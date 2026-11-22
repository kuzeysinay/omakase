"""Billing, entitlement sync, and RevenueCat webhook endpoints (/billing/*)."""

from __future__ import annotations

import asyncio
import hmac
from typing import Any, Optional

from fastapi import APIRouter, Body, Depends, Header, Query

from app.config import REVENUECAT_WEBHOOK_SECRET
from app.errors import ErrorCode, OmakaseAPIError
from app.schemas import BillingSyncRequest
from app.security import _check_rate_limit, extract_uid, verify_firebase_user
from app.services.access_service import build_access_snapshot
from app.services.billing_service import (
    handle_revenuecat_webhook,
    sync_revenuecat_subscriber,
)

router = APIRouter(prefix="/billing", tags=["billing"])


def _verify_webhook_authorization(authorization: Optional[str]) -> None:
    if not REVENUECAT_WEBHOOK_SECRET:
        raise OmakaseAPIError(
            status_code=503,
            code=ErrorCode.BILLING_SYNC_FAILED,
            detail="Webhook secret is not configured.",
        )
    if not authorization:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Invalid webhook authorization.",
        )
    raw = authorization.strip()
    token = raw[7:].strip() if raw.lower().startswith("bearer ") else raw
    if not token or not hmac.compare_digest(token, REVENUECAT_WEBHOOK_SECRET):
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Invalid webhook authorization.",
        )


@router.get("/status")
async def billing_status(
    timezone: Optional[str] = Query(default=None, max_length=64),
    x_omakase_timezone: Optional[str] = Header(default=None),
    caller_id: str = Depends(verify_firebase_user),
) -> dict[str, Any]:
    """Return the signed-in user's entitlement and daily quota snapshot."""
    _check_rate_limit(caller_id, bucket="billing_status", max_calls=30)
    uid = extract_uid(caller_id)
    if not uid:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Authentication required.",
        )
    tz = timezone or x_omakase_timezone
    return await asyncio.to_thread(build_access_snapshot, uid, tz)


@router.post("/sync")
async def billing_sync(
    req: BillingSyncRequest = Body(default_factory=BillingSyncRequest),
    x_omakase_timezone: Optional[str] = Header(default=None),
    caller_id: str = Depends(verify_firebase_user),
) -> dict[str, Any]:
    """Verify the user's RevenueCat subscriber state immediately after purchase or restore."""
    _check_rate_limit(caller_id, bucket="billing_sync", max_calls=10)
    uid = extract_uid(caller_id)
    if not uid:
        raise OmakaseAPIError(
            status_code=401,
            code=ErrorCode.UNAUTHORIZED,
            detail="Authentication required.",
        )
    await sync_revenuecat_subscriber(uid)
    tz = req.timezone or x_omakase_timezone
    return await asyncio.to_thread(build_access_snapshot, uid, tz)


@router.post("/revenuecat-webhook")
async def revenuecat_webhook(
    payload: dict[str, Any],
    authorization: Optional[str] = Header(default=None),
) -> dict[str, Any]:
    """Receive RevenueCat subscription lifecycle webhooks and update Firestore entitlements."""
    _verify_webhook_authorization(authorization)
    return await handle_revenuecat_webhook(payload)
