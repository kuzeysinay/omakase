"""RevenueCat subscriber verification and webhook event processor."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from typing import Any, Optional
from urllib.parse import quote

import httpx

from app.config import (
    REVENUECAT_ENTITLEMENT_ID,
    REVENUECAT_SECRET_API_KEY,
    logger,
)
from app.errors import ErrorCode, OmakaseAPIError
from app.services.access_service import parse_iso_datetime, set_entitlement

_REVENUECAT_BASE_URL = "https://api.revenuecat.com/v1"


def _ms_to_iso(ms_val: Any) -> Optional[str]:
    if ms_val is None:
        return None
    try:
        ms_num = float(ms_val)
    except (TypeError, ValueError):
        return None
    dt = datetime.fromtimestamp(ms_num / 1000.0, tz=timezone.utc)
    return dt.isoformat().replace("+00:00", "Z")


def _extract_from_subscriber_payload(subscriber: dict[str, Any]) -> dict[str, Any]:
    entitlements = subscriber.get("entitlements") or {}
    subscriptions = subscriber.get("subscriptions") or {}
    ent = entitlements.get(REVENUECAT_ENTITLEMENT_ID)
    if not isinstance(ent, dict):
        return {
            "is_pro": False,
            "status": "free",
            "product_id": None,
            "expires_at": None,
            "will_renew": False,
            "source": "revenuecat_sync",
        }

    product_id = ent.get("product_identifier")
    expires_raw = ent.get("expires_date")
    expires_dt = parse_iso_datetime(expires_raw)
    now_utc = datetime.now(timezone.utc)
    is_active = expires_dt is None or expires_dt > now_utc

    sub_info = subscriptions.get(product_id) if isinstance(subscriptions, dict) and product_id else None
    sub_dict = sub_info if isinstance(sub_info, dict) else {}
    period_type = str(sub_dict.get("period_type") or "").lower()
    billing_issue_at = sub_dict.get("billing_issues_detected_at")
    unsubscribe_at = sub_dict.get("unsubscribe_detected_at")

    if is_active:
        if billing_issue_at:
            status = "billing_issue"
        elif period_type == "trial":
            status = "trial"
        else:
            status = "active"
    else:
        status = "expired"

    will_renew = is_active and (unsubscribe_at is None)
    expires_iso = expires_dt.isoformat().replace("+00:00", "Z") if expires_dt else None

    return {
        "is_pro": is_active,
        "status": status,
        "product_id": str(product_id) if product_id else None,
        "expires_at": expires_iso,
        "will_renew": will_renew,
        "source": "revenuecat_sync",
    }


async def sync_revenuecat_subscriber(uid: str) -> dict[str, Any]:
    """Fetch authoritative subscriber state from RevenueCat REST API and write to Firestore."""
    if not REVENUECAT_SECRET_API_KEY:
        raise OmakaseAPIError(
            status_code=503,
            code=ErrorCode.BILLING_SYNC_FAILED,
            detail="Billing verification service is temporarily unavailable.",
        )

    url = f"{_REVENUECAT_BASE_URL}/subscribers/{quote(uid, safe='')}"
    headers = {
        "Authorization": f"Bearer {REVENUECAT_SECRET_API_KEY}",
        "Accept": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, headers=headers)
    except httpx.HTTPError as exc:
        logger.warning("RevenueCat REST sync failed for %s: %s", uid, exc)
        raise OmakaseAPIError(
            status_code=502,
            code=ErrorCode.BILLING_SYNC_FAILED,
            detail="Could not verify subscription with RevenueCat.",
        ) from exc

    if resp.status_code == 404:
        free_state = {
            "is_pro": False,
            "status": "free",
            "product_id": None,
            "expires_at": None,
            "will_renew": False,
            "source": "revenuecat_sync",
        }
        return await asyncio.to_thread(set_entitlement, uid, free_state)

    if not (200 <= resp.status_code < 300):
        logger.warning(
            "RevenueCat REST sync returned HTTP %s for %s",
            resp.status_code,
            uid,
        )
        raise OmakaseAPIError(
            status_code=502,
            code=ErrorCode.BILLING_SYNC_FAILED,
            detail="Could not verify subscription with RevenueCat.",
        )

    body = resp.json()
    subscriber = body.get("subscriber") if isinstance(body, dict) else None
    if not isinstance(subscriber, dict):
        raise OmakaseAPIError(
            status_code=502,
            code=ErrorCode.BILLING_SYNC_FAILED,
            detail="Unexpected RevenueCat subscriber payload.",
        )

    entitlement_state = _extract_from_subscriber_payload(subscriber)
    return await asyncio.to_thread(set_entitlement, uid, entitlement_state)


def _event_matches_entitlement(event: dict[str, Any]) -> bool:
    entitlement_ids = event.get("entitlement_ids")
    if isinstance(entitlement_ids, list) and entitlement_ids:
        return REVENUECAT_ENTITLEMENT_ID in [str(x) for x in entitlement_ids]
    single_entitlement = event.get("entitlement_id")
    if single_entitlement is not None:
        return str(single_entitlement) == REVENUECAT_ENTITLEMENT_ID
    return True


def _entitlement_from_webhook_event(event: dict[str, Any], event_type: str) -> dict[str, Any]:
    expires_at = _ms_to_iso(event.get("expiration_at_ms"))
    expires_dt = parse_iso_datetime(expires_at)
    now_utc = datetime.now(timezone.utc)
    not_yet_expired = expires_dt is None or expires_dt > now_utc
    period_type = str(event.get("period_type") or "").upper()
    product_id = event.get("product_id")

    if event_type in (
        "INITIAL_PURCHASE",
        "RENEWAL",
        "UNCANCELLATION",
        "PRODUCT_CHANGE",
        "NON_RENEWING_PURCHASE",
    ):
        is_pro = not_yet_expired
        will_renew = event_type != "NON_RENEWING_PURCHASE" and is_pro
        status = ("trial" if period_type == "TRIAL" else "active") if is_pro else "expired"
    elif event_type == "CANCELLATION":
        is_pro = not_yet_expired
        will_renew = False
        status = ("trial" if period_type == "TRIAL" else "active") if is_pro else "expired"
    elif event_type == "BILLING_ISSUE":
        is_pro = not_yet_expired
        will_renew = False
        status = "billing_issue" if is_pro else "expired"
    elif event_type == "EXPIRATION":
        is_pro = False
        will_renew = False
        status = "expired"
    else:
        is_pro = not_yet_expired
        will_renew = False
        status = "active" if is_pro else "free"

    return {
        "is_pro": is_pro,
        "status": status,
        "product_id": str(product_id) if product_id else None,
        "expires_at": expires_at,
        "will_renew": will_renew,
        "source": f"webhook:{event_type.lower()}",
    }


async def handle_revenuecat_webhook(payload: dict[str, Any]) -> dict[str, Any]:
    """Process a RevenueCat webhook event and update `entitlements/{uid}`."""
    event = payload.get("event") if isinstance(payload, dict) else None
    if not isinstance(event, dict):
        raise OmakaseAPIError(
            status_code=400,
            code=ErrorCode.INVALID_REQUEST,
            detail="Missing webhook event payload.",
        )

    event_type = str(event.get("type") or "").strip().upper()
    if event_type == "TEST":
        return {"status": "ok", "handled": "test"}

    if event_type == "TRANSFER":
        transferred_from = [str(u) for u in (event.get("transferred_from") or []) if u]
        transferred_to = [str(u) for u in (event.get("transferred_to") or []) if u]
        for from_uid in transferred_from:
            try:
                await sync_revenuecat_subscriber(from_uid)
            except OmakaseAPIError:
                await asyncio.to_thread(
                    set_entitlement,
                    from_uid,
                    {
                        "is_pro": False,
                        "status": "free",
                        "product_id": None,
                        "expires_at": None,
                        "will_renew": False,
                        "source": "webhook:transfer_from",
                    },
                )
        for to_uid in transferred_to:
            try:
                await sync_revenuecat_subscriber(to_uid)
            except OmakaseAPIError:
                fallback = _entitlement_from_webhook_event(event, "INITIAL_PURCHASE")
                fallback["source"] = "webhook:transfer_to"
                await asyncio.to_thread(set_entitlement, to_uid, fallback)
        return {"status": "ok", "handled": "transfer"}

    if not _event_matches_entitlement(event):
        return {"status": "ignored", "reason": "different_entitlement"}

    uid = str(event.get("app_user_id") or event.get("original_app_user_id") or "").strip()
    if not uid or uid.startswith("$RCAnonymousID:"):
        logger.info("Ignoring RevenueCat webhook %s without Firebase UID (%r)", event_type, uid)
        return {"status": "ignored", "reason": "anonymous_user"}

    handled_types = {
        "INITIAL_PURCHASE",
        "RENEWAL",
        "UNCANCELLATION",
        "PRODUCT_CHANGE",
        "NON_RENEWING_PURCHASE",
        "CANCELLATION",
        "EXPIRATION",
        "BILLING_ISSUE",
    }
    if event_type not in handled_types:
        return {"status": "ignored", "event_type": event_type}

    state = _entitlement_from_webhook_event(event, event_type)
    await asyncio.to_thread(set_entitlement, uid, state)
    return {"status": "ok", "uid": uid, "event_type": event_type}
