"""Atomic daily metrics aggregation, feedback persistence, and optional admin alerts."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import re
from typing import Any, Optional
import uuid

from firebase_admin import firestore
import httpx

from app.config import (
    ADMIN_ALERT_WEBHOOK_URL,
    logger,
    normalize_language,
)
from app.errors import ErrorCode
from app.schemas import FeedbackSubmitRequest, TelemetryBatchRequest
from app.services.firestore_admin import get_firestore_client

_SEEN_ACTIVE_DAY_UIDS: set[tuple[str, str]] = set()
_TOPIC_CLEAN_RE = re.compile(r"[^a-z0-9]+")
_ALLOWED_PAYWALL_SOURCES = frozenset(
    {"firstPlateSoft", "plateLimit", "deepDiveLimit", "profile"}
)


def utc_day_key(dt: Optional[datetime] = None) -> str:
    """Return UTC date string formatted as `YYYY-MM-DD`."""
    target = dt.astimezone(timezone.utc) if dt else datetime.now(timezone.utc)
    return target.strftime("%Y-%m-%d")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _slugify_topic(raw: str) -> str:
    ascii_ish = (
        (raw or "")
        .strip()
        .lower()
        .replace("ı", "i")
        .replace("ğ", "g")
        .replace("ü", "u")
        .replace("ş", "s")
        .replace("ö", "o")
        .replace("ç", "c")
    )
    slug = _TOPIC_CLEAN_RE.sub("_", ascii_ish).strip("_")
    return slug[:32]


def estimate_gemini_cost_microusd(
    model: str,
    input_tokens: int,
    output_tokens: int,
) -> int:
    """Estimate Gemini API cost in micro-USD (1 USD = 1_000_000 microusd)."""
    is_lite = "lite" in (model or "").lower()
    in_rate_per_million = 0.075 if is_lite else 0.15
    out_rate_per_million = 0.30 if is_lite else 0.60
    usd = (
        max(0, int(input_tokens)) * in_rate_per_million / 1_000_000.0
        + max(0, int(output_tokens)) * out_rate_per_million / 1_000_000.0
    )
    return max(0, int(round(usd * 1_000_000.0)))


def _apply_increments(
    db: Any,
    collection_name: str,
    doc_id: str,
    increments: dict[str, int],
    extra_fields: Optional[dict[str, Any]] = None,
) -> None:
    """Atomically increment integer fields on Firestore (with _FakeFirestore fallback for tests)."""
    clean_increments = {k: int(v) for k, v in increments.items() if v}
    if not clean_increments and not extra_fields:
        return

    doc_ref = db.collection(collection_name).document(doc_id)
    if hasattr(db, "execute_fake_transaction"):
        snap = doc_ref.get()
        current = snap.to_dict() if snap.exists else {}
        if current is None:
            current = {}
        updated = dict(current)
        for key, delta in clean_increments.items():
            updated[key] = int(updated.get(key) or 0) + delta
        if extra_fields:
            updated.update(extra_fields)
        doc_ref.set(updated, merge=True)
        return

    payload: dict[str, Any] = {
        key: firestore.Increment(delta) for key, delta in clean_increments.items()
    }
    if extra_fields:
        payload.update(extra_fields)
    doc_ref.set(payload, merge=True)


def _touch_daily_active_sync(
    db: Any,
    uid: Optional[str],
    day_key: str,
    language: str = "en",
) -> None:
    if not uid:
        return
    cache_key = (day_key, uid)
    if cache_key in _SEEN_ACTIVE_DAY_UIDS:
        return
    if len(_SEEN_ACTIVE_DAY_UIDS) > 10_000:
        _SEEN_ACTIVE_DAY_UIDS.clear()
    _SEEN_ACTIVE_DAY_UIDS.add(cache_key)

    doc_id = f"{day_key}_{uid}"
    doc_ref = db.collection("daily_active").document(doc_id)
    doc_ref.set(
        {
            "date": day_key,
            "uid": uid,
            "language": normalize_language(language),
            "lastSeenAt": _now_iso(),
        },
        merge=True,
    )


def record_generation_sync(
    kind: str,
    *,
    uid: Optional[str] = None,
    language: str = "en",
    model: str = "",
    input_tokens: int = 0,
    output_tokens: int = 0,
    letterboxd: bool = False,
    topics: Optional[list[str]] = None,
) -> None:
    """Record a successful AI generation event and token/cost counters into `metrics_daily`."""
    try:
        db = get_firestore_client()
        if db is None:
            return
        day = utc_day_key()
        lang = normalize_language(language)
        increments: dict[str, int] = {
            f"lang_{lang}": 1,
            "gemini_input_tokens": max(0, int(input_tokens)),
            "gemini_output_tokens": max(0, int(output_tokens)),
            "gemini_cost_microusd": estimate_gemini_cost_microusd(
                model, input_tokens, output_tokens
            ),
        }
        if kind == "plate":
            increments["plates_generated"] = 1
            if letterboxd:
                increments["letterboxd_plates"] = 1
        elif kind == "deep_dive":
            increments["deep_dives_generated"] = 1
        elif kind == "suggestion":
            increments["suggestions_generated"] = 1
        elif kind == "category_expansion":
            increments["category_expansions"] = 1

        if topics and kind == "plate":
            seen_slugs: set[str] = set()
            for raw_topic in topics[:3]:
                slug = _slugify_topic(raw_topic)
                if slug and slug not in seen_slugs:
                    seen_slugs.add(slug)
                    increments[f"topic_{slug}"] = 1

        _apply_increments(
            db,
            "metrics_daily",
            day,
            increments,
            extra_fields={"date": day, "updatedAt": _now_iso()},
        )
        _touch_daily_active_sync(db, uid, day, lang)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to record generation metric (%s): %s", kind, exc)


async def record_generation_async(
    kind: str,
    *,
    uid: Optional[str] = None,
    language: str = "en",
    model: str = "",
    input_tokens: int = 0,
    output_tokens: int = 0,
    letterboxd: bool = False,
    topics: Optional[list[str]] = None,
) -> None:
    await asyncio.to_thread(
        record_generation_sync,
        kind,
        uid=uid,
        language=language,
        model=model,
        input_tokens=input_tokens,
        output_tokens=output_tokens,
        letterboxd=letterboxd,
        topics=topics,
    )


def record_api_error_sync(
    code: str,
    *,
    status_code: int = 500,
    safety_blocked: bool = False,
) -> None:
    """Record an API or model error counter into `metrics_daily`."""
    try:
        db = get_firestore_client()
        if db is None:
            return
        day = utc_day_key()
        safe_code = _TOPIC_CLEAN_RE.sub("_", (code or ErrorCode.UNKNOWN).lower()).strip("_")[:40]
        if not safe_code:
            safe_code = ErrorCode.UNKNOWN
        increments: dict[str, int] = {
            "api_errors": 1,
            f"error_code_{safe_code}": 1,
        }
        if safety_blocked or code == ErrorCode.CONTENT_BLOCKED:
            increments["safety_blocks"] = 1
        if status_code == 429 or code == ErrorCode.RATE_LIMITED:
            increments["rate_limits"] = 1
        if code == ErrorCode.QUOTA_EXCEEDED:
            increments["quota_blocks"] = 1

        _apply_increments(
            db,
            "metrics_daily",
            day,
            increments,
            extra_fields={"date": day, "updatedAt": _now_iso()},
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to record API error metric (%s): %s", code, exc)


async def record_api_error_async(
    code: str,
    *,
    status_code: int = 500,
    safety_blocked: bool = False,
) -> None:
    await asyncio.to_thread(
        record_api_error_sync,
        code,
        status_code=status_code,
        safety_blocked=safety_blocked,
    )


def record_api_error_background(code: str, status_code: int = 500) -> None:
    """Schedule non-blocking error counter persistence from async exception handlers."""
    if code in (ErrorCode.UNAUTHORIZED, ErrorCode.FORBIDDEN):
        return
    try:
        loop = asyncio.get_running_loop()
        loop.create_task(record_api_error_async(code, status_code=status_code))
    except RuntimeError:
        record_api_error_sync(code, status_code=status_code)


def record_billing_event_sync(
    event_type: str,
    *,
    is_trial: bool = False,
    revenue_usd: float = 0.0,
) -> None:
    """Record a RevenueCat subscription lifecycle webhook into `metrics_daily`."""
    try:
        db = get_firestore_client()
        if db is None:
            return
        day = utc_day_key()
        clean_type = _TOPIC_CLEAN_RE.sub("_", (event_type or "unknown").lower()).strip("_")
        increments: dict[str, int] = {
            f"rc_{clean_type}": 1,
        }
        if event_type.upper() == "INITIAL_PURCHASE":
            if is_trial:
                increments["rc_trial_started"] = 1
            else:
                increments["rc_paid_started"] = 1
        cents = max(0, int(round(float(revenue_usd or 0.0) * 100.0)))
        if cents > 0:
            increments["rc_revenue_cents"] = cents

        _apply_increments(
            db,
            "metrics_daily",
            day,
            increments,
            extra_fields={"date": day, "updatedAt": _now_iso()},
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to record billing metric (%s): %s", event_type, exc)


async def record_billing_event_async(
    event_type: str,
    *,
    is_trial: bool = False,
    revenue_usd: float = 0.0,
) -> None:
    await asyncio.to_thread(
        record_billing_event_sync,
        event_type,
        is_trial=is_trial,
        revenue_usd=revenue_usd,
    )


def record_share_bonus_sync(uid: Optional[str]) -> None:
    try:
        db = get_firestore_client()
        if db is None:
            return
        day = utc_day_key()
        _apply_increments(
            db,
            "metrics_daily",
            day,
            {"share_bonuses_claimed": 1},
            extra_fields={"date": day, "updatedAt": _now_iso()},
        )
        _touch_daily_active_sync(db, uid, day)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to record share bonus metric: %s", exc)


def record_telemetry_batch_sync(uid: Optional[str], req: TelemetryBatchRequest) -> int:
    """Aggregate batched client events into `metrics_daily` and mark DAU."""
    db = get_firestore_client()
    if db is None:
        return len(req.events)

    day = utc_day_key()
    lang = normalize_language(req.language)
    increments: dict[str, int] = {}
    for ev in req.events:
        increments[f"event_{ev.name}"] = increments.get(f"event_{ev.name}", 0) + 1
        if ev.name == "paywall_viewed":
            src = str(ev.properties.get("source") or "").strip()
            if src in _ALLOWED_PAYWALL_SOURCES:
                key = f"paywall_source_{src}"
                increments[key] = increments.get(key, 0) + 1

    _apply_increments(
        db,
        "metrics_daily",
        day,
        increments,
        extra_fields={"date": day, "updatedAt": _now_iso()},
    )
    _touch_daily_active_sync(db, uid, day, lang)
    return len(req.events)


async def record_telemetry_batch_async(
    uid: Optional[str], req: TelemetryBatchRequest
) -> int:
    return await asyncio.to_thread(record_telemetry_batch_sync, uid, req)


async def send_admin_alert(title: str, body: str) -> None:
    """Send a best-effort Discord/Slack/generic webhook alert when ADMIN_ALERT_WEBHOOK_URL is set."""
    url = (ADMIN_ALERT_WEBHOOK_URL or "").strip()
    if not url:
        return
    message = f"**{title}**\n{body}" if "discord" in url.lower() else f"*{title}*\n{body}"
    payload: dict[str, Any]
    lower_url = url.lower()
    if "discord" in lower_url:
        payload = {"content": message[:1900]}
    elif "slack" in lower_url:
        payload = {"text": message[:3000]}
    else:
        payload = {"title": title, "text": body, "content": message}
    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            await client.post(url, json=payload)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Admin alert webhook failed: %s", exc)


def submit_user_feedback_sync(
    uid: str,
    req: FeedbackSubmitRequest,
) -> dict[str, Any]:
    """Persist user feedback enriched with profile & subscription metadata."""
    db = get_firestore_client()
    now_iso = _now_iso()
    feedback_id = str(uuid.uuid4())

    display_name = ""
    username = ""
    email = ""
    is_pro = False
    sub_status = "free"

    if db is not None:
        try:
            user_snap = db.collection("users").document(uid).get()
            if user_snap.exists:
                u = user_snap.to_dict() or {}
                display_name = str(u.get("displayName") or "")
                username = str(u.get("username") or "")
                email = str(u.get("email") or "")
        except Exception as exc:  # noqa: BLE001
            logger.warning("Could not enrich feedback user profile (%s): %s", uid, exc)

        try:
            ent_snap = db.collection("entitlements").document(uid).get()
            if ent_snap.exists:
                e = ent_snap.to_dict() or {}
                is_pro = bool(e.get("isPro", e.get("is_pro", False)))
                sub_status = str(e.get("status") or ("active" if is_pro else "free"))
        except Exception as exc:  # noqa: BLE001
            logger.warning("Could not enrich feedback entitlement (%s): %s", uid, exc)

    doc = {
        "id": feedback_id,
        "uid": uid,
        "displayName": display_name,
        "username": username,
        "email": email,
        "isPro": is_pro,
        "subscriptionStatus": sub_status,
        "category": req.category,
        "message": req.message,
        "rating": req.rating,
        "appVersion": req.app_version,
        "osVersion": req.os_version,
        "deviceModel": req.device_model,
        "language": normalize_language(req.language),
        "screen": req.screen,
        "status": "new",
        "adminNote": "",
        "createdAt": now_iso,
        "updatedAt": now_iso,
    }

    if db is not None:
        db.collection("user_feedback").document(feedback_id).set(doc)
        day = utc_day_key()
        _apply_increments(
            db,
            "metrics_daily",
            day,
            {"event_feedback_submitted": 1},
            extra_fields={"date": day, "updatedAt": now_iso},
        )
        _touch_daily_active_sync(db, uid, day, req.language)

    return doc


async def submit_user_feedback_async(
    uid: str,
    req: FeedbackSubmitRequest,
) -> dict[str, Any]:
    doc = await asyncio.to_thread(submit_user_feedback_sync, uid, req)
    rating_part = f" · {req.rating}★" if req.rating else ""
    user_label = f"@{doc['username']}" if doc.get("username") else (doc.get("displayName") or uid[:8])
    await send_admin_alert(
        f"Yeni Geri Bildirim [{req.category.upper()}{rating_part}]",
        f"Kimden: {user_label} ({'PRO' if doc.get('isPro') else 'FREE'}) · {req.language}\n{req.message[:400]}",
    )
    return doc
