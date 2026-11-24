"""Omakase FastAPI application entrypoint.

Run locally:

    uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import ALLOWED_CORS_ORIGINS
from app.errors import ErrorCode, OmakaseAPIError
from app.prompts import _build_deep_dive_prompt, _build_user_prompt
from app.routers import admin, billing, feed, interests, letterboxd, notifications, telemetry
from app.schemas import (
    DeepDiveRequest,
    ExpandCategoryRequest,
    FeedRequest,
    LetterboxdFilmsRequest,
    SuggestRequest,
)
from app.security import _check_rate_limit, verify_firebase_user
from app.services.letterboxd_service import _parse_letterboxd_rss
from app.services.metrics_service import record_api_error_background

app = FastAPI(title="Omakase", version="0.1.0")

# Restrict CORS to official Omakase web origins and local dev servers (S-07).
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_CORS_ORIGINS,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=[
        "Authorization",
        "Content-Type",
        "Accept",
        "X-Omakase-Timezone",
        "X-Omakase-Device-Id",
        "X-Omakase-App-Version",
        "X-Omakase-OS-Version",
    ],
)

app.include_router(admin.router)
app.include_router(billing.router)
app.include_router(feed.router)
app.include_router(interests.router)
app.include_router(letterboxd.router)
app.include_router(notifications.router)
app.include_router(telemetry.router)


@app.exception_handler(OmakaseAPIError)
async def omakase_api_error_handler(
    _request: Request,
    exc: OmakaseAPIError,
) -> JSONResponse:
    """Serialize structured API errors with canonical `code` and optional headers."""
    record_api_error_background(exc.code, exc.status_code)
    body: dict[str, object] = {"code": exc.code, "detail": exc.detail}
    if exc.extra:
        body.update(exc.extra)
    return JSONResponse(
        status_code=exc.status_code,
        content=body,
        headers=exc.headers,
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    _request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    """Return canonical error codes for Pydantic/request validation failures."""
    errors = exc.errors()
    is_blocked = any(
        "inappropriate content" in str(err.get("msg", "")).lower()
        for err in errors
    )
    if is_blocked:
        return JSONResponse(
            status_code=422,
            content={
                "code": ErrorCode.CONTENT_BLOCKED,
                "detail": "Inappropriate content.",
            },
        )
    return JSONResponse(
        status_code=422,
        content={
            "code": ErrorCode.INVALID_REQUEST,
            "detail": "Invalid request payload.",
        },
    )


@app.get("/health", tags=["system"])
async def health() -> dict[str, str]:
    """Minimal liveness probe."""
    return {"status": "ok"}


__all__ = [
    "app",
    "health",
    "FeedRequest",
    "SuggestRequest",
    "ExpandCategoryRequest",
    "DeepDiveRequest",
    "LetterboxdFilmsRequest",
    "verify_firebase_user",
    "_check_rate_limit",
    "_parse_letterboxd_rss",
    "_build_user_prompt",
    "_build_deep_dive_prompt",
]
