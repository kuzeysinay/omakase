"""Feed SSE streaming endpoints (/feed/stream and /feed/deep-dive)."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse

from app.schemas import DeepDiveRequest, FeedRequest
from app.security import _check_rate_limit, verify_firebase_user
from app.services.gemini_service import _stream_deep_dive, _stream_post

router = APIRouter(prefix="/feed", tags=["feed"])


@router.post("/stream")
async def feed_stream(
    req: FeedRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> StreamingResponse:
    """Stream a single generated post as Server-Sent Events."""
    _check_rate_limit(caller_id, "feed_stream", max_calls=20, window_seconds=60)
    if len(req.interests) > 50:
        raise HTTPException(status_code=400, detail="Too many interests (max 50).")

    headers = {
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
        "X-Accel-Buffering": "no",
    }
    return StreamingResponse(
        _stream_post(
            req.interests,
            req.seen_count,
            req.language,
            letterboxd_films=req.letterboxd_films,
        ),
        media_type="text/event-stream",
        headers=headers,
    )


@router.post("/deep-dive")
async def deep_dive(
    req: DeepDiveRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> StreamingResponse:
    """Stream a deep-dive expansion of an existing post as Server-Sent Events."""
    _check_rate_limit(caller_id, "deep_dive", max_calls=20, window_seconds=60)
    return StreamingResponse(
        _stream_deep_dive(req),
        media_type="text/event-stream",
        headers={"X-Accel-Buffering": "no", "Cache-Control": "no-cache"},
    )
