"""Omakase FastAPI application entrypoint.

Run locally:

    uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import ALLOWED_CORS_ORIGINS
from app.prompts import _build_deep_dive_prompt, _build_user_prompt
from app.routers import feed, interests, letterboxd
from app.schemas import (
    DeepDiveRequest,
    ExpandCategoryRequest,
    FeedRequest,
    LetterboxdFilmsRequest,
    SuggestRequest,
)
from app.security import _check_rate_limit, verify_firebase_user
from app.services.letterboxd_service import _parse_letterboxd_rss

app = FastAPI(title="Omakase", version="0.1.0")

# Restrict CORS to official Omakase web origins and local dev servers (S-07).
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_CORS_ORIGINS,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

app.include_router(feed.router)
app.include_router(interests.router)
app.include_router(letterboxd.router)


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
