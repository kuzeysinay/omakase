"""Unit tests for Gemini SSE stream header (TITLE:/TAGS:) parsing."""

from __future__ import annotations

import asyncio
import unittest

from app.services.gemini_service import _feed_tokens_from_stream_chunks


class _Chunk:
    def __init__(self, text: str) -> None:
        self.text = text
        self.candidates = []


class _Candidate:
    def __init__(self, finish_reason: str) -> None:
        self.finish_reason = finish_reason
        self.content = None


class _FinishChunk:
    def __init__(self, finish_reason: str) -> None:
        self.text = ""
        self.candidates = [_Candidate(finish_reason)]


def _run_chunks_with_status(chunks: list[object]) -> tuple[str, list[str]]:
    async def _collect():
        queue: asyncio.Queue = asyncio.Queue()
        loop = asyncio.get_running_loop()
        status = _feed_tokens_from_stream_chunks(chunks, queue, loop)
        await asyncio.sleep(0)
        events: list[str] = []
        while not queue.empty():
            kind, _payload = queue.get_nowait()
            events.append(kind)
        return status, events

    return asyncio.run(_collect())


def _run_chunks(chunks: list[str]) -> tuple[list[str], list[list[str]], str]:
    async def _collect():
        queue: asyncio.Queue = asyncio.Queue()
        loop = asyncio.get_running_loop()
        _feed_tokens_from_stream_chunks([_Chunk(c) for c in chunks], queue, loop)
        await asyncio.sleep(0)
        titles: list[str] = []
        tags: list[list[str]] = []
        tokens: list[str] = []
        while not queue.empty():
            kind, payload = queue.get_nowait()
            if kind == "title":
                titles.append(payload)
            elif kind == "tags":
                tags.append(payload)
            elif kind == "token":
                tokens.append(payload)
        return titles, tags, "".join(tokens)

    return asyncio.run(_collect())


class StreamParserTests(unittest.TestCase):
    def test_standard_title_tags_body(self) -> None:
        titles, tags, body = _run_chunks([
            "TITLE: Studio Ghibli Soundtracks\n",
            "TAGS: Film, Music\n",
            "Joe Hisaishi recorded the score in Tokyo.",
        ])
        self.assertEqual(titles, ["Studio Ghibli Soundtracks"])
        self.assertEqual(tags, [["Film", "Music"]])
        self.assertEqual(body, "Joe Hisaishi recorded the score in Tokyo.")

    def test_leading_blank_lines_and_blank_separator(self) -> None:
        titles, tags, body = _run_chunks([
            "\n\nTITLE: Parasite's Basement Staircase\n\n",
            "TAGS: Letterboxd, Parasite, Architecture\n\n",
            "Bong Joon-ho built the entire house set specifically around camera angles.",
        ])
        self.assertEqual(titles, ["Parasite's Basement Staircase"])
        self.assertEqual(tags, [["Letterboxd", "Parasite", "Architecture"]])
        self.assertEqual(
            body,
            "Bong Joon-ho built the entire house set specifically around camera angles.",
        )

    def test_markdown_wrapped_headers(self) -> None:
        titles, tags, body = _run_chunks([
            "**TITLE:** Why Kubrick Used Candlelight\n",
            "**TAGS:** Film, Barry Lyndon\n",
            "NASA loaned Zeiss f/0.7 lenses for the shoot.",
        ])
        self.assertEqual(titles, ["Why Kubrick Used Candlelight"])
        self.assertEqual(tags, [["Film", "Barry Lyndon"]])
        self.assertEqual(body, "NASA loaned Zeiss f/0.7 lenses for the shoot.")

    def test_heading_prefix_and_split_chunks(self) -> None:
        titles, tags, body = _run_chunks([
            "### TI",
            "TLE: Nighthawks Lighting\n",
            "TAGS: Art, Hopper\nBody ",
            "starts here.",
        ])
        self.assertEqual(titles, ["Nighthawks Lighting"])
        self.assertEqual(tags, [["Art", "Hopper"]])
        self.assertEqual(body, "Body starts here.")

    def test_stop_finish_reason_is_ok(self) -> None:
        status, events = _run_chunks_with_status([
            _Chunk("TITLE: Heat's Diners\n"),
            _Chunk("TAGS: Film\n"),
            _Chunk("Michael Mann recorded real restaurant ambience."),
            _FinishChunk("FinishReason.STOP"),
        ])
        self.assertEqual(status, "ok")
        self.assertNotIn("truncated", events)

    def test_max_tokens_after_text_marks_truncated(self) -> None:
        # Real-world Letterboxd failure: thinking tokens consumed max_output_tokens,
        # so Gemini stopped after one sentence. The post must not be treated as done.
        status, events = _run_chunks_with_status([
            _Chunk("TITLE: Chungking Express\nTAGS: Film\n\nWong Kar-wai, *Ashes of Time*\n"),
            _FinishChunk("FinishReason.MAX_TOKENS"),
        ])
        self.assertEqual(status, "truncated")
        self.assertIn("truncated", events)
        self.assertNotIn("done", events)

    def test_safety_after_text_marks_truncated(self) -> None:
        status, _events = _run_chunks_with_status([
            _Chunk("TITLE: A Film\nTAGS: Film\nSome partial body text."),
            _FinishChunk("FinishReason.SAFETY"),
        ])
        self.assertEqual(status, "truncated")

    def test_safety_before_text_marks_blocked(self) -> None:
        status, events = _run_chunks_with_status([
            _FinishChunk("FinishReason.PROHIBITED_CONTENT"),
        ])
        self.assertEqual(status, "blocked")
        self.assertIn("blocked", events)


if __name__ == "__main__":
    unittest.main()
