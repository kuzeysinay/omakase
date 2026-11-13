"""Gemini SSE streaming engine, token drip-feeder, and suggestion generators."""

from __future__ import annotations

import asyncio
import json
import re
from typing import Any, AsyncIterator, Optional
import uuid

from fastapi import HTTPException
from google.genai import types

from app.config import (
    GEMINI_API_KEY,
    GEMINI_DEEP_DIVE_MODEL,
    GEMINI_MODEL,
    GEMINI_SUGGEST_MODEL,
    SAFETY_SETTINGS,
    genai_client,
    logger,
)
from app.prompts import (
    _DEEP_DIVE_SYSTEM,
    _POST_FORMATS,
    _build_deep_dive_prompt,
    _build_user_prompt,
    _deep_dive_language_instruction,
    _expand_system_for_language,
    _feed_system_instruction,
    _suggest_system_for_language,
)
from app.schemas import DeepDiveRequest, ExpandCategoryRequest, SuggestRequest

_TITLE_LINE = re.compile(r"(?i)^TITLE:\s*(.+)$")
_TAGS_LINE = re.compile(r"(?i)^TAGS:\s*(.+)$")

# Gemini often emits the entire post body in one stream delta. Clients expect multiple small
# `token` SSE events so the Swift UI can animate like Gemini in the browser.
_SPLIT_STREAM_SOFT_CAP = 6

# Artificial delay (seconds) inserted between SSE token events to create a smooth
# typing cadence on the client.
_TOKEN_DRIP_DELAY = 0.045


def _split_fragment_for_smooth_stream(
    fragment: str, *, max_piece: int = _SPLIT_STREAM_SOFT_CAP
) -> list[str]:
    """Split large model deltas into modest substrings, preferring word boundaries."""
    if not fragment:
        return []
    if len(fragment) <= max_piece:
        return [fragment]
    chunks: list[str] = []
    idx = 0
    fragment_len = len(fragment)
    min_wordish = max(2, max_piece // 6)
    while idx < fragment_len:
        end = min(idx + max_piece, fragment_len)
        if end >= fragment_len:
            tail = fragment[idx:]
            if tail:
                chunks.append(tail)
            break
        window = fragment[idx:end]
        cut = window.rfind(" ")
        if cut >= min_wordish:
            end = idx + cut + 1
        chunks.append(fragment[idx:end])
        idx = end
    return chunks if chunks else [fragment]


def _enqueue_stream_body_fragment(
    loop: asyncio.AbstractEventLoop,
    queue: asyncio.Queue,
    fragment: str,
) -> None:
    for piece in _split_fragment_for_smooth_stream(fragment):
        loop.call_soon_threadsafe(queue.put_nowait, ("token", piece))


def _stream_chunk_text(chunk: object) -> str:
    """Best-effort text from a streaming chunk (Gemini SDK quirks vary by chunk)."""
    try:
        cands = getattr(chunk, "candidates", None) or []
        if cands:
            content = getattr(cands[0], "content", None)
            parts = getattr(content, "parts", None) if content is not None else None
            if parts:
                pieces: list[str] = []
                for part in parts:
                    if getattr(part, "thought", False):
                        continue
                    txt = getattr(part, "text", None)
                    if txt:
                        pieces.append(str(txt))
                return "".join(pieces)
    except (IndexError, AttributeError, TypeError):
        pass

    try:
        t = getattr(chunk, "text", None)
        if t:
            return str(t)
    except (ValueError, AttributeError):
        pass
    return ""


def _feed_tokens_from_stream_chunks(
    response: Any,
    queue: asyncio.Queue,
    loop: asyncio.AbstractEventLoop,
) -> None:
    """Turn Gemini stream chunks into queue items.

    Emits ('title', str), then ('tags', list[str]), then body ('token', str) events.
    """
    carry = ""
    title_done = False
    tags_done = False
    for chunk in response:
        text = _stream_chunk_text(chunk)
        if not text:
            continue
        carry += text
        if not title_done:
            if "\n" not in carry:
                continue
            first_line, carry = carry.split("\n", 1)
            m = _TITLE_LINE.match(first_line.strip())
            if m:
                loop.call_soon_threadsafe(
                    queue.put_nowait,
                    ("title", m.group(1).strip()),
                )
            else:
                carry = first_line + "\n" + carry
            title_done = True
        if title_done and not tags_done:
            if "\n" not in carry:
                continue
            second_line, rest = carry.split("\n", 1)
            mt = _TAGS_LINE.match(second_line.strip())
            if mt:
                raw_tags = [t.strip() for t in mt.group(1).split(",") if t.strip()]
                loop.call_soon_threadsafe(
                    queue.put_nowait,
                    ("tags", raw_tags),
                )
                carry = rest
            else:
                carry = second_line + "\n" + rest
            tags_done = True
        if carry:
            _enqueue_stream_body_fragment(loop, queue, carry)
            carry = ""
    if not title_done and carry:
        loop.call_soon_threadsafe(queue.put_nowait, ("token", carry))
    elif title_done and carry:
        _enqueue_stream_body_fragment(loop, queue, carry)


def _sse_event(data: dict, *, event: str | None = None) -> str:
    """Format a payload as a single SSE frame."""
    lines: list[str] = []
    if event:
        lines.append(f"event: {event}")
    lines.append(f"data: {json.dumps(data, ensure_ascii=False)}")
    lines.append("")
    lines.append("")
    return "\n".join(lines)


async def _stream_post(
    interests: list[str],
    seen_count: int,
    language: str,
    letterboxd_films: Optional[list[dict]] = None,
) -> AsyncIterator[str]:
    """Yield SSE frames for one generated post."""
    post_id = str(uuid.uuid4())
    yield _sse_event({"id": post_id}, event="start")

    if letterboxd_films:
        format_name = "LETTERBOXD DIARY"
    else:
        format_name, _ = _POST_FORMATS[seen_count % len(_POST_FORMATS)]
    yield _sse_event({"format": format_name}, event="format")

    if not GEMINI_API_KEY or genai_client is None:
        yield _sse_event(
            {"message": "Content generation service is temporarily unavailable."},
            event="error",
        )
        return

    prompt = _build_user_prompt(
        interests, seen_count, language, letterboxd_films=letterboxd_films
    )

    try:
        queue: asyncio.Queue[tuple[str, Any]] = asyncio.Queue()
        loop = asyncio.get_running_loop()

        def _produce() -> None:
            try:
                assert genai_client is not None
                response = genai_client.models.generate_content_stream(
                    model=GEMINI_MODEL,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=_feed_system_instruction(language),
                        thinking_config=types.ThinkingConfig(thinking_budget=1024),
                        safety_settings=SAFETY_SETTINGS,
                    ),
                )
                _feed_tokens_from_stream_chunks(response, queue, loop)
                loop.call_soon_threadsafe(queue.put_nowait, ("done", None))
            except Exception as exc:  # noqa: BLE001
                loop.call_soon_threadsafe(queue.put_nowait, ("error", exc))

        producer = asyncio.create_task(asyncio.to_thread(_produce))

        saw_any_output = False
        saw_error = False
        while True:
            kind, payload = await queue.get()
            if kind == "token":
                saw_any_output = True
                yield _sse_event({"text": payload}, event="token")
                yield ": flush\n\n"
                await asyncio.sleep(_TOKEN_DRIP_DELAY)
            elif kind == "title":
                saw_any_output = True
                yield _sse_event({"title": str(payload)}, event="title")
            elif kind == "tags":
                saw_any_output = True
                final_tags = list(payload)
                if letterboxd_films and "Letterboxd" not in final_tags:
                    final_tags.insert(0, "Letterboxd")
                yield _sse_event({"tags": final_tags}, event="tags")
            elif kind == "done":
                break
            elif kind == "error":
                saw_error = True
                logger.exception("Gemini streaming failed", exc_info=payload)
                yield _sse_event(
                    {"message": "Could not generate a post right now. Please try again."},
                    event="error",
                )
                break

        await producer

        if not saw_any_output and not saw_error:
            logger.warning("Gemini returned empty stream for model=%s", GEMINI_MODEL)
            yield _sse_event(
                {"message": "Could not generate a post right now. Please try again."},
                event="error",
            )

    except asyncio.CancelledError:
        logger.info("Client disconnected from stream %s", post_id)
        raise

    yield _sse_event({"id": post_id}, event="done")


async def _stream_deep_dive(req: DeepDiveRequest) -> AsyncIterator[str]:
    """Yield SSE frames for a deep-dive expansion of an existing post."""
    post_id = str(uuid.uuid4())
    yield _sse_event({"id": post_id}, event="start")

    if not GEMINI_API_KEY or genai_client is None:
        yield _sse_event(
            {"message": "Content generation service is temporarily unavailable."},
            event="error",
        )
        return

    system = _DEEP_DIVE_SYSTEM + "\n\n" + _deep_dive_language_instruction(req.language)
    prompt = _build_deep_dive_prompt(req)

    try:
        queue: asyncio.Queue[tuple[str, Any]] = asyncio.Queue()
        loop = asyncio.get_running_loop()

        def _produce() -> None:
            try:
                assert genai_client is not None
                response = genai_client.models.generate_content_stream(
                    model=GEMINI_DEEP_DIVE_MODEL,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=system,
                        thinking_config=types.ThinkingConfig(thinking_budget=1024),
                        safety_settings=SAFETY_SETTINGS,
                    ),
                )
                _feed_tokens_from_stream_chunks(response, queue, loop)
                loop.call_soon_threadsafe(queue.put_nowait, ("done", None))
            except Exception as exc:  # noqa: BLE001
                loop.call_soon_threadsafe(queue.put_nowait, ("error", exc))

        producer = asyncio.create_task(asyncio.to_thread(_produce))

        saw_any_output = False
        saw_error = False
        while True:
            kind, payload = await queue.get()
            if kind == "token":
                saw_any_output = True
                yield _sse_event({"text": payload}, event="token")
                yield ": flush\n\n"
                await asyncio.sleep(_TOKEN_DRIP_DELAY)
            elif kind == "title":
                saw_any_output = True
                yield _sse_event({"title": str(payload)}, event="title")
            elif kind == "tags":
                saw_any_output = True
                yield _sse_event({"tags": payload}, event="tags")
            elif kind == "done":
                break
            elif kind == "error":
                saw_error = True
                logger.exception("Gemini deep-dive streaming failed", exc_info=payload)
                yield _sse_event(
                    {"message": "Could not generate a deep dive right now. Please try again."},
                    event="error",
                )
                break

        await producer

        if not saw_any_output and not saw_error:
            logger.warning(
                "Gemini deep-dive returned empty stream for model=%s",
                GEMINI_DEEP_DIVE_MODEL,
            )
            yield _sse_event(
                {"message": "Could not generate a deep dive right now. Please try again."},
                event="error",
            )

    except asyncio.CancelledError:
        logger.info("Client disconnected from deep-dive stream %s", post_id)
        raise

    yield _sse_event({"id": post_id}, event="done")


def _generative_response_text(response: object) -> str:
    """Best-effort plain text from google-genai (handles blocked / multi-part replies)."""
    try:
        text = response.text  # type: ignore[attr-defined]
        if isinstance(text, str) and text.strip():
            return text.strip()
    except Exception:  # noqa: BLE001
        pass
    candidates = getattr(response, "candidates", None) or []
    if not candidates:
        return ""
    parts_out: list[str] = []
    for cand in candidates:
        content = getattr(cand, "content", None)
        parts = getattr(content, "parts", None) if content is not None else None
        if not parts:
            continue
        for part in parts:
            t = getattr(part, "text", None)
            if isinstance(t, str) and t:
                parts_out.append(t)
    return "".join(parts_out).strip()


def _parse_suggestion_strings(raw: str) -> list[str]:
    """Parse model output into a list of suggestion strings (JSON array, with fallbacks)."""
    s = raw.strip()
    s = s.removeprefix("```json").removeprefix("```").removesuffix("```").strip()

    def _loads_list(payload: str) -> list[str]:
        data = json.loads(payload)
        if not isinstance(data, list):
            raise ValueError("Model did not return a JSON array.")
        return [str(x) for x in data if x]

    try:
        return _loads_list(s)
    except (json.JSONDecodeError, ValueError, TypeError):
        pass

    start = s.find("[")
    end = s.rfind("]")
    if start != -1 and end > start:
        try:
            return _loads_list(s[start : end + 1])
        except (json.JSONDecodeError, ValueError, TypeError):
            pass

    quoted = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', s)
    if len(quoted) >= 3:
        return quoted[:10]

    raise ValueError(
        f"Could not parse suggestions from model output (first 200 chars): {s[:200]!r}"
    )


async def generate_interest_suggestions(req: SuggestRequest) -> list[str]:
    """Generate ~7 interest suggestions for the caller."""
    if not GEMINI_API_KEY or genai_client is None:
        raise HTTPException(
            status_code=503,
            detail="Suggestion service is temporarily unavailable.",
        )

    existing = [i.strip() for i in req.interests if i.strip()]
    draft = req.draft.strip()
    excluded = [s.strip() for s in req.exclude_suggestions if s.strip()]

    parts: list[str] = []
    if existing:
        parts.append("Interests already added: " + ", ".join(existing) + ".")
    if draft:
        parts.append(
            f'The user is currently typing: "{draft}".  '
            "Include suggestions related to this term as well."
        )
    if not parts:
        parts.append(
            "The user hasn't added any interests yet. Suggest a diverse, intriguing starter set."
        )
    if excluded:
        parts.append(
            "These ideas were already shown — suggest 7 completely different ones (do not repeat or "
            "minorly rephrase): " + ", ".join(excluded) + "."
        )

    user_prompt = (
        "<user_context>\n"
        + " ".join(parts)
        + "\n</user_context>\n\nRespond with a JSON array only."
    )

    try:
        response = await asyncio.to_thread(
            genai_client.models.generate_content,
            model=GEMINI_SUGGEST_MODEL,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=_suggest_system_for_language(req.language),
                thinking_config=types.ThinkingConfig(thinking_budget=0),
                safety_settings=SAFETY_SETTINGS,
            ),
        )
        raw = _generative_response_text(response)
        if not raw:
            fr = None
            candidates = getattr(response, "candidates", None)
            if candidates:
                fr = getattr(candidates[0], "finish_reason", None)
            logger.warning("Interest suggestion: empty model text (finish_reason=%s)", fr)
            raise ValueError(
                "Model returned no text (blocked, empty, or unsupported response)."
            )
        return _parse_suggestion_strings(raw)[:10]
    except Exception as exc:  # noqa: BLE001
        logger.warning("Interest suggestion failed: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Could not generate suggestions right now.",
        ) from exc


async def generate_category_expansion(req: ExpandCategoryRequest) -> list[str]:
    """Generate ~10 sub-interest suggestions within a broad category."""
    if not GEMINI_API_KEY or genai_client is None:
        raise HTTPException(
            status_code=503,
            detail="Category expansion service is temporarily unavailable.",
        )

    parts: list[str] = [f'Category tapped: "{req.category}".']
    if req.existing_interests:
        parts.append(
            "User already has these interests (do NOT repeat): "
            + ", ".join(req.existing_interests)
            + "."
        )
    user_prompt = (
        "<user_context>\n"
        + " ".join(parts)
        + "\n</user_context>\n\nRespond with a JSON array only."
    )

    try:
        response = await asyncio.to_thread(
            genai_client.models.generate_content,
            model=GEMINI_SUGGEST_MODEL,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=_expand_system_for_language(req.language),
                thinking_config=types.ThinkingConfig(thinking_budget=0),
                safety_settings=SAFETY_SETTINGS,
            ),
        )
        raw = _generative_response_text(response)
        if not raw:
            raise ValueError("Model returned no text.")
        return _parse_suggestion_strings(raw)[:12]
    except Exception as exc:  # noqa: BLE001
        logger.warning("Category expansion failed: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Could not expand category right now.",
        ) from exc
