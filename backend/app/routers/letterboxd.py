"""Letterboxd RSS integration endpoint (/letterboxd/films)."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.schemas import LetterboxdFilmsRequest
from app.security import _check_rate_limit, verify_firebase_user
from app.services.letterboxd_service import fetch_letterboxd_films

router = APIRouter(prefix="/letterboxd", tags=["letterboxd"])


@router.post("/films")
async def letterboxd_films(
    req: LetterboxdFilmsRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> dict:
    """Fetch a user's recently watched films from their Letterboxd RSS feed."""
    _check_rate_limit(caller_id, "letterboxd", max_calls=10, window_seconds=60)
    films = await fetch_letterboxd_films(req)
    return {"films": films, "username": req.username}
