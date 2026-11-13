"""Interest discovery and category expansion endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.schemas import ExpandCategoryRequest, SuggestRequest
from app.security import _check_rate_limit, verify_firebase_user
from app.services.gemini_service import (
    generate_category_expansion,
    generate_interest_suggestions,
)

router = APIRouter(prefix="/interests", tags=["interests"])


@router.post("/suggest")
async def interests_suggest(
    req: SuggestRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> dict:
    """Return ~7 AI-generated interest suggestions based on what the user already has."""
    _check_rate_limit(caller_id, "suggest", max_calls=30, window_seconds=60)
    suggestions = await generate_interest_suggestions(req)
    return {"suggestions": suggestions}


@router.post("/expand-category")
async def expand_category(
    req: ExpandCategoryRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> dict:
    """Return ~10 specific interest suggestions within a broad category."""
    _check_rate_limit(caller_id, "expand_category", max_calls=30, window_seconds=60)
    suggestions = await generate_category_expansion(req)
    return {"suggestions": suggestions}
