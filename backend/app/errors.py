"""Canonical API error codes, exception type, and Gemini error classifier."""

from __future__ import annotations

from typing import Any, Optional


class ErrorCode:
    """Canonical error codes shared between the backend and iOS client."""

    UNAUTHORIZED = "unauthorized"
    RATE_LIMITED = "rate_limited"
    QUOTA_EXCEEDED = "quota_exceeded"
    CONTENT_BLOCKED = "content_blocked"
    GENERATION_FAILED = "generation_failed"
    SERVICE_UNAVAILABLE = "service_unavailable"
    LETTERBOXD_NOT_FOUND = "letterboxd_not_found"
    LETTERBOXD_PRIVATE = "letterboxd_private"
    INVALID_REQUEST = "invalid_request"
    BILLING_SYNC_FAILED = "billing_sync_failed"
    UNKNOWN = "unknown"


class OmakaseAPIError(Exception):
    """Structured HTTP error serialized with a canonical `code` field."""

    def __init__(
        self,
        status_code: int,
        code: str,
        detail: str,
        *,
        headers: Optional[dict[str, str]] = None,
        extra: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(detail)
        self.status_code = status_code
        self.code = code
        self.detail = detail
        self.headers = headers
        self.extra = extra


_SAFETY_TOKENS = ("safety", "prohibited", "blocklist", "spii", "blocked")
_RATE_LIMIT_TOKENS = ("429", "resource_exhausted", "rate limit", "quota")
_UNAVAILABLE_TOKENS = (
    "503",
    "500",
    "unavailable",
    "api_key",
    "api key",
    "connection",
    "timeout",
    "timed out",
)


def classify_gemini_exception(exc: BaseException) -> str:
    """Map a google-genai SDK exception to a canonical backend error code."""
    text = f"{type(exc).__name__}: {exc}".lower()
    if any(token in text for token in _SAFETY_TOKENS):
        return ErrorCode.CONTENT_BLOCKED
    if any(token in text for token in _RATE_LIMIT_TOKENS):
        return ErrorCode.RATE_LIMITED
    if any(token in text for token in _UNAVAILABLE_TOKENS):
        return ErrorCode.SERVICE_UNAVAILABLE
    return ErrorCode.GENERATION_FAILED
