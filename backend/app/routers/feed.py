"""Feed SSE streaming endpoints (/feed/stream, /feed/deep-dive, /feed/reward-share)."""

from __future__ import annotations

from typing import Any, Optional

from fastapi import APIRouter, Body, Depends, Header
from fastapi.responses import StreamingResponse

from app.errors import ErrorCode, OmakaseAPIError
from app.schemas import DeepDiveRequest, FeedRequest, RewardShareRequest
from app.security import _check_rate_limit, extract_uid, verify_firebase_user
from app.services.access_service import (
    assert_quota_available,
    claim_share_bonus,
    record_quota_usage,
)
from app.services.gemini_service import _stream_deep_dive, _stream_post

router = APIRouter(prefix="/feed", tags=["feed"])


@router.post("/stream")
async def feed_stream(
    req: FeedRequest,
    x_omakase_timezone: Optional[str] = Header(default=None),
    caller_id: str = Depends(verify_firebase_user),
) -> StreamingResponse:
    """Stream a single generated post as Server-Sent Events."""
    _check_rate_limit(caller_id, "feed_stream", max_calls=20, window_seconds=60)
    if len(req.interests) > 50:
        raise OmakaseAPIError(
            status_code=400,
            code=ErrorCode.INVALID_REQUEST,
            detail="Too many interests (max 50).",
        )

    uid = extract_uid(caller_id)
    tz = req.timezone or x_omakase_timezone
    await assert_quota_available(uid, "plate", tz)

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
            on_complete=(lambda: record_quota_usage(uid, "plate", tz)) if uid else None,
        ),
        media_type="text/event-stream",
        headers=headers,
    )


@router.post("/deep-dive")
async def deep_dive(
    req: DeepDiveRequest,
    x_omakase_timezone: Optional[str] = Header(default=None),
    caller_id: str = Depends(verify_firebase_user),
) -> StreamingResponse:
    """Stream a deep-dive expansion of an existing post as Server-Sent Events."""
    _check_rate_limit(caller_id, "deep_dive", max_calls=20, window_seconds=60)
    uid = extract_uid(caller_id)
    tz = req.timezone or x_omakase_timezone
    await assert_quota_available(uid, "deep_dive", tz)

    return StreamingResponse(
        _stream_deep_dive(
            req,
            on_complete=(lambda: record_quota_usage(uid, "deep_dive", tz)) if uid else None,
        ),
        media_type="text/event-stream",
        headers={"X-Accel-Buffering": "no", "Cache-Control": "no-cache"},
    )


@router.post("/reward-share")
async def reward_share(
    req: RewardShareRequest = Body(default_factory=RewardShareRequest),
    x_omakase_timezone: Optional[str] = Header(default=None),
    caller_id: str = Depends(verify_firebase_user),
) -> dict[str, Any]:
    """Grant once-per-day +2 Deep Dive bonus after sharing a plate."""
    _check_rate_limit(caller_id, "reward_share", max_calls=10, window_seconds=60)
    uid = extract_uid(caller_id)
    if not uid:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Authentication required.",
        )
    tz = req.timezone or x_omakase_timezone
    return await claim_share_bonus(uid, tz)
