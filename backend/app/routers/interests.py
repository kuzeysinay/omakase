"""Interest discovery and category expansion endpoints."""

from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, Header

from app.schemas import ExpandCategoryRequest, SuggestRequest
from app.security import _check_rate_limit, extract_uid, verify_firebase_user
from app.services.access_service import assert_quota_available, record_quota_usage
from app.services.gemini_service import (
    generate_category_expansion,
    generate_interest_suggestions,
)

router = APIRouter(prefix="/interests", tags=["interests"])


@router.post("/suggest")
async def interests_suggest(
    req: SuggestRequest,
    x_omakase_timezone: Optional[str] = Header(default=None),
    caller_id: str = Depends(verify_firebase_user),
) -> dict:
    """Return ~7 AI-generated interest suggestions based on what the user already has."""
    _check_rate_limit(caller_id, "suggest", max_calls=30, window_seconds=60)
    uid = extract_uid(caller_id)
    tz = req.timezone or x_omakase_timezone
    await assert_quota_available(uid, "suggestion", tz)
    suggestions = await generate_interest_suggestions(req)
    await record_quota_usage(uid, "suggestion", tz)
    return {"suggestions": suggestions}


@router.post("/expand-category")
async def expand_category(
    req: ExpandCategoryRequest,
    x_omakase_timezone: Optional[str] = Header(default=None),
    caller_id: str = Depends(verify_firebase_user),
) -> dict:
    """Return ~10 specific interest suggestions within a broad category."""
    _check_rate_limit(caller_id, "expand_category", max_calls=30, window_seconds=60)
    uid = extract_uid(caller_id)
    tz = req.timezone or x_omakase_timezone
    await assert_quota_available(uid, "suggestion", tz)
    suggestions = await generate_category_expansion(req)
    await record_quota_usage(uid, "suggestion", tz)
    return {"suggestions": suggestions}
