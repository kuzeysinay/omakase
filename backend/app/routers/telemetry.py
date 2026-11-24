"""Authenticated client telemetry & in-app user feedback endpoints."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends

from app.errors import ErrorCode, OmakaseAPIError
from app.schemas import FeedbackSubmitRequest, TelemetryBatchRequest
from app.security import _check_rate_limit, extract_uid, verify_firebase_user
from app.services.metrics_service import (
    record_telemetry_batch_async,
    submit_user_feedback_async,
)

router = APIRouter(tags=["telemetry"])


@router.post("/telemetry/events")
async def ingest_telemetry_events(
    req: TelemetryBatchRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> dict[str, Any]:
    """Ingest a batch of allowlisted non-tracking product interaction events."""
    _check_rate_limit(caller_id, bucket="telemetry_events", max_calls=60, window_seconds=60)
    uid = extract_uid(caller_id)
    accepted = await record_telemetry_batch_async(uid, req)
    return {"status": "ok", "accepted": accepted}


@router.post("/feedback")
async def submit_feedback(
    req: FeedbackSubmitRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> dict[str, Any]:
    """Submit user feedback, bug report, or content note from inside the iOS app."""
    _check_rate_limit(caller_id, bucket="feedback_submit", max_calls=5, window_seconds=60)
    uid = extract_uid(caller_id)
    if not uid:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Authentication required.",
        )
    doc = await submit_user_feedback_async(uid, req)
    return {"status": "ok", "id": doc["id"]}
