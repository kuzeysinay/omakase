"""Authentication, sliding-window rate limiting, content moderation, and input sanitizers."""

from __future__ import annotations

import asyncio
from collections import defaultdict, deque
import hashlib
import math
import re
import time
from typing import Any, Optional

from fastapi import Header, Request as FastAPIRequest
import firebase_admin
from firebase_admin import auth as firebase_auth

from app.config import (
    ADMIN_EMAILS,
    ADMIN_UIDS,
    FIREBASE_PROJECT_ID,
    REQUIRE_AUTH,
    logger,
)
from app.errors import ErrorCode, OmakaseAPIError

_RATE_BUCKETS: dict[str, deque[float]] = defaultdict(deque)
_RATE_BUCKET_LAST_SEEN: dict[str, float] = {}
_MAX_RATE_BUCKET_KEYS = 4096
_RATE_BUCKET_IDLE_TTL_SECONDS = 300.0
_LAST_RATE_PRUNE_AT = 0.0


def _verify_firebase_id_token(token: str) -> dict[str, Any]:
    """Verify Firebase ID token with revocation and strict claim checks enabled."""
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={"projectId": FIREBASE_PROJECT_ID})
    return firebase_auth.verify_id_token(token, check_revoked=True)

# ---------------------------------------------------------------------------
# Content moderation — first-pass guard at the API boundary.
# Gemini's built-in safety filters handle the heavy lifting; this blocklist
# catches obviously harmful / spam input before it ever reaches the model.
# ---------------------------------------------------------------------------

_BLOCKLIST_RE = re.compile(
    r"(?i)\b("
    # Adult / NSFW / Sexual (EN & TR stems)
    r"porn\w*|porno\w*|hentai|xxx|nsfw|nude\w*|naked|sext\w*|erotik\w*|erotic\w*|"
    r"seks\w*|sex\w*|cinsel|masturbat\w*|mastürbat\w*|orgasm\w*|vajina|penis|"
    # Violence / Abuse / Illegal (EN & TR)
    r"child\s*abuse|cocuk\s*istismar\w*|çocuk\s*istismar\w*|pedofil\w*|pedophil\w*|"
    r"rape|tecavuz\w*|tecavüz\w*|snuff|murder\s*tutorial|cinayet\s*egitim\w*|"
    r"kill\s*(?:my)?self|intihar\w*|suicide\w*|"
    r"bomb\s*making|bomba\s*yap\w*|terrorist|terör\w*|teror\w*|"
    r"drug\s*deal|uyusturucu\w*|uyuşturucu\w*|kokain\w*|eroin\w*|meth\w*|"
    r"buy\s*(?:guns?|weapons?)|silah\s*sat\w*|"
    r"hack\s*(?:into|account|password)|hesap\s*cal\w*|hesap\s*çal\w*|"
    r"kumar|bahis|betting|casino"
    r")\b"
)

_MAX_INTEREST_LEN = 100
_MAX_INTERESTS = 30
_MAX_LETTERBOXD_FILMS = 50
_MAX_RSS_BYTES = 2_000_000
_LETTERBOXD_USERNAME_RE = re.compile(r"^[a-zA-Z0-9_-]{1,40}$")


def _prune_rate_buckets(now: float) -> None:
    """Evict idle/expired rate-limit buckets to bound in-memory cardinality (S-20)."""
    global _LAST_RATE_PRUNE_AT
    if (
        len(_RATE_BUCKETS) <= _MAX_RATE_BUCKET_KEYS
        and (now - _LAST_RATE_PRUNE_AT) < _RATE_BUCKET_IDLE_TTL_SECONDS
    ):
        return
    _LAST_RATE_PRUNE_AT = now
    stale_keys = [
        k
        for k, last_seen in list(_RATE_BUCKET_LAST_SEEN.items())
        if (now - last_seen) >= _RATE_BUCKET_IDLE_TTL_SECONDS or not _RATE_BUCKETS.get(k)
    ]
    for k in stale_keys:
        _RATE_BUCKETS.pop(k, None)
        _RATE_BUCKET_LAST_SEEN.pop(k, None)
    if len(_RATE_BUCKETS) > _MAX_RATE_BUCKET_KEYS:
        oldest = sorted(_RATE_BUCKET_LAST_SEEN.items(), key=lambda kv: kv[1])
        for k, _ in oldest[: len(_RATE_BUCKETS) - _MAX_RATE_BUCKET_KEYS]:
            _RATE_BUCKETS.pop(k, None)
            _RATE_BUCKET_LAST_SEEN.pop(k, None)


def _check_rate_limit(
    caller_id: str,
    bucket: str,
    max_calls: int,
    window_seconds: int = 60,
) -> None:
    """Enforce a per-caller sliding-window rate limit with bounded TTL eviction (S-20)."""
    now = time.monotonic()
    _prune_rate_buckets(now)
    key = f"{bucket}:{caller_id}"
    q = _RATE_BUCKETS[key]
    cutoff = now - window_seconds
    while q and q[0] < cutoff:
        q.popleft()
    if len(q) >= max_calls:
        _RATE_BUCKET_LAST_SEEN[key] = now
        retry_after = max(1, math.ceil(window_seconds - (now - q[0])))
        raise OmakaseAPIError(
            status_code=429,
            code=ErrorCode.RATE_LIMITED,
            detail="Too many requests. Please wait a moment and try again.",
            headers={"Retry-After": str(retry_after)},
            extra={"retry_after": retry_after},
        )
    q.append(now)
    _RATE_BUCKET_LAST_SEEN[key] = now


async def verify_firebase_user(
    request: FastAPIRequest,
    authorization: Optional[str] = Header(default=None),
) -> str:
    """Verify the caller's Firebase ID token and return a rate-limit caller key."""
    client_host = request.client.host if request.client else "unknown"
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization[7:].strip()
        if token:
            try:
                claims = await asyncio.to_thread(_verify_firebase_id_token, token)
                uid = str(claims.get("user_id") or claims.get("sub") or "")
                if uid:
                    return f"uid:{uid}"
            except Exception as exc:  # noqa: BLE001
                logger.warning("Invalid Firebase ID token from %s: %s", client_host, exc)
                if REQUIRE_AUTH:
                    raise OmakaseAPIError(
                        status_code=401,
                        code=ErrorCode.UNAUTHORIZED,
                        detail="Invalid or expired authentication token.",
                    ) from exc

    if REQUIRE_AUTH:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Authentication required.",
        )

    return f"ip:{client_host}"


def extract_uid(caller_id: str) -> Optional[str]:
    """Extract the Firebase UID from a verified caller key (`uid:<uid>`)."""
    if caller_id.startswith("uid:"):
        uid = caller_id[4:].strip()
        return uid or None
    return None


def _is_authorized_admin_claims(uid: str, email: str, email_verified: bool) -> bool:
    if uid and uid in ADMIN_UIDS:
        return True
    if email_verified and email and email.lower() in ADMIN_EMAILS:
        return True
    return False


async def verify_admin_user(
    request: FastAPIRequest,
    authorization: Optional[str] = Header(default=None),
) -> dict[str, Any]:
    """Strictly verify a Firebase ID token and ensure the caller is in ADMIN_UIDS/ADMIN_EMAILS."""
    client_host = request.client.host if request.client else "unknown"
    if not authorization or not authorization.lower().startswith("bearer "):
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Admin authentication required.",
        )

    token = authorization[7:].strip()
    if not token:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Admin authentication required.",
        )

    try:
        claims = await asyncio.to_thread(_verify_firebase_id_token, token)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Invalid admin Firebase token from %s: %s", client_host, exc)
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
        ) from exc

    uid = str(claims.get("user_id") or claims.get("sub") or "").strip()
    email = str(claims.get("email") or "").strip().lower()
    email_verified = bool(claims.get("email_verified", False))
    if not uid:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Invalid authentication token.",
        )

    if not _is_authorized_admin_claims(uid, email, email_verified):
        logger.warning("Unauthorized admin access attempt uid=%s email=%s", uid, email or "-")
        raise OmakaseAPIError(
            status_code=403,
            code=ErrorCode.FORBIDDEN,
            detail="Admin access required.",
        )

    return {"uid": uid, "email": email, "caller_id": f"uid:{uid}"}


def _sanitize_single_line(value: str, max_len: int) -> str:
    """Strip newlines, carriage returns, and NUL bytes."""
    cleaned = re.sub(r"[\r\n\x00]+", " ", value or "").strip()
    return cleaned[:max_len]


def _validate_interests(interests: list[str]) -> list[str]:
    """Sanitize and validate a list of interest strings.

    Strips whitespace/control chars, enforces length limits, and rejects blocklisted content.
    Raises ValueError so Pydantic surfaces it as a 422 response.
    """
    cleaned: list[str] = []
    for raw in interests:
        item = _sanitize_single_line(raw, _MAX_INTEREST_LEN)
        if not item:
            continue
        if _BLOCKLIST_RE.search(item):
            raise ValueError(f"Interest contains inappropriate content: {item!r}")
        cleaned.append(item)
    if len(cleaned) > _MAX_INTERESTS:
        raise ValueError(f"Too many interests (max {_MAX_INTERESTS}).")
    return cleaned


def _validate_letterboxd_films(films: Optional[list[dict]]) -> Optional[list[dict]]:
    """Sanitize and bound optional Letterboxd film dicts (S-02, S-08)."""
    if films is None:
        return None
    if len(films) > _MAX_LETTERBOXD_FILMS:
        raise ValueError(f"Too many Letterboxd films (max {_MAX_LETTERBOXD_FILMS}).")
    sanitized: list[dict] = []
    for raw in films:
        if not isinstance(raw, dict):
            continue
        title = _sanitize_single_line(str(raw.get("title") or ""), 200)
        if not title:
            continue
        if _BLOCKLIST_RE.search(title):
            continue
        year_val = raw.get("year")
        year: Optional[int] = None
        if isinstance(year_val, int) and 1880 <= year_val <= 2100:
            year = year_val
        rating_val = raw.get("rating")
        rating: Optional[float] = None
        if isinstance(rating_val, (int, float)) and 0.0 <= float(rating_val) <= 5.0:
            rating = round(float(rating_val), 2)
        watched_val = raw.get("watched_date")
        watched_date = _sanitize_single_line(str(watched_val), 20) if watched_val else None
        sanitized.append(
            {
                "title": title,
                "year": year,
                "rating": rating,
                "watched_date": watched_date,
            }
        )
    return sanitized or None
