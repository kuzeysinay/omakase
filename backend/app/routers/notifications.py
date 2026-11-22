"""Notification endpoints (/notifications/*) for social push events and scheduled queue flush."""

from __future__ import annotations

import hmac
from typing import Any, Optional

from fastapi import APIRouter, Depends, Header

from app.config import NOTIFICATION_CRON_SECRET
from app.errors import ErrorCode, OmakaseAPIError
from app.schemas import SocialNotificationEventRequest
from app.security import _check_rate_limit, extract_uid, verify_firebase_user
from app.services.notification_service import (
    process_due_notifications_async,
    record_social_event_async,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _verify_cron_secret(
    x_omakase_cron_secret: Optional[str],
    authorization: Optional[str],
) -> None:
    if not NOTIFICATION_CRON_SECRET:
        raise OmakaseAPIError(
            status_code=503,
            code=ErrorCode.SERVICE_UNAVAILABLE,
            detail="Notification cron secret is not configured.",
        )

    candidate: Optional[str] = None
    if x_omakase_cron_secret:
        candidate = x_omakase_cron_secret.strip()
    elif authorization:
        raw = authorization.strip()
        candidate = raw[7:].strip() if raw.lower().startswith("bearer ") else raw

    if not candidate or not hmac.compare_digest(candidate, NOTIFICATION_CRON_SECRET):
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Invalid cron authorization.",
        )


@router.post("/events")
async def record_notification_event(
    req: SocialNotificationEventRequest,
    caller_id: str = Depends(verify_firebase_user),
) -> dict[str, Any]:
    """Record a comment, follow, or reaction social notification event."""
    _check_rate_limit(caller_id, bucket="notifications_events", max_calls=30)
    uid = extract_uid(caller_id)
    if not uid:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Authentication required.",
        )
    return await record_social_event_async(uid, req)


@router.post("/process-queue")
async def process_notification_queue(
    x_omakase_cron_secret: Optional[str] = Header(default=None),
    authorization: Optional[str] = Header(default=None),
) -> dict[str, Any]:
    """Process due grouped comment notifications and daily social digests (Cloud Scheduler)."""
    _verify_cron_secret(x_omakase_cron_secret, authorization)
    return await process_due_notifications_async()
