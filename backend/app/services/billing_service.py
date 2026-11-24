"""RevenueCat subscriber verification and webhook event processor."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import time
from typing import Any, Optional
from urllib.parse import quote

import httpx

from app.config import (
    REVENUECAT_ENTITLEMENT_ID,
    REVENUECAT_PROJECT_ID,
    REVENUECAT_SECRET_API_KEY,
    REVENUECAT_V2_SECRET_API_KEY,
    logger,
)
from app.errors import ErrorCode, OmakaseAPIError
from app.services.access_service import parse_iso_datetime, set_entitlement
from app.services.metrics_service import record_billing_event_async, send_admin_alert

_REVENUECAT_BASE_URL = "https://api.revenuecat.com/v1"
_REVENUECAT_V2_BASE_URL = "https://api.revenuecat.com/v2"
_RC_OVERVIEW_CACHE: dict[str, Any] = {"expires_at": 0.0, "data": None}
_RC_OVERVIEW_TTL_SECONDS = 300.0


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

    period_type = str(event.get("period_type") or "").upper()
    raw_price = event.get("price_in_purchased_currency")
    if raw_price is None:
        raw_price = event.get("price")
    try:
        revenue_usd = float(event.get("price") or 0.0)
    except (TypeError, ValueError):
        revenue_usd = 0.0

    await record_billing_event_async(
        event_type,
        is_trial=(period_type == "TRIAL"),
        revenue_usd=revenue_usd,
    )
    if event_type in ("INITIAL_PURCHASE", "RENEWAL", "BILLING_ISSUE"):
        await send_admin_alert(
            f"RevenueCat: {event_type}",
            f"UID: {uid[:12]}… · Plan: {state.get('product_id') or '-'} · Durum: {state.get('status')} · Tutar: ${revenue_usd:.2f}",
        )
    return {"status": "ok", "uid": uid, "event_type": event_type}


async def fetch_revenuecat_overview_metrics(force_refresh: bool = False) -> dict[str, Any]:
    """Fetch 28-day RevenueCat v2 overview metrics with 5-minute TTL cache and graceful fallback."""
    now_mono = time.monotonic()
    cached_data = _RC_OVERVIEW_CACHE.get("data")
    if not force_refresh and cached_data is not None and now_mono < float(_RC_OVERVIEW_CACHE.get("expires_at") or 0.0):
        return cached_data

    api_key = (REVENUECAT_V2_SECRET_API_KEY or REVENUECAT_SECRET_API_KEY or "").strip()
    if not api_key:
        result = {
            "connected": False,
            "mode": "firestore_fallback",
            "project_id": REVENUECAT_PROJECT_ID,
            "currency": "USD",
            "reason": "REVENUECAT_V2_SECRET_API_KEY tanımlı değil; Firestore abonelikleri kullanılıyor.",
            "metrics": {},
        }
        _RC_OVERVIEW_CACHE["data"] = result
        _RC_OVERVIEW_CACHE["expires_at"] = now_mono + 60.0
        return result

    url = f"{_REVENUECAT_V2_BASE_URL}/projects/{quote(REVENUECAT_PROJECT_ID, safe='')}/metrics/overview?currency=USD"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json",
    }
    try:
        async with httpx.AsyncClient(timeout=6.0) as client:
            resp = await client.get(url, headers=headers)
    except httpx.HTTPError as exc:
        logger.warning("RevenueCat v2 overview fetch failed: %s", exc)
        return {
            "connected": False,
            "mode": "firestore_fallback",
            "project_id": REVENUECAT_PROJECT_ID,
            "currency": "USD",
            "reason": f"RevenueCat API ağ hatası: {type(exc).__name__}",
            "metrics": {},
        }

    if not (200 <= resp.status_code < 300):
        reason = (
            "v2 API anahtarı yetkisi yok (REVENUECAT_V2_SECRET_API_KEY gerekir); Firestore abonelikleri kullanılıyor."
            if resp.status_code in (401, 403)
            else f"RevenueCat HTTP {resp.status_code}"
        )
        result = {
            "connected": False,
            "mode": "firestore_fallback",
            "project_id": REVENUECAT_PROJECT_ID,
            "currency": "USD",
            "reason": reason,
            "metrics": {},
        }
        _RC_OVERVIEW_CACHE["data"] = result
        _RC_OVERVIEW_CACHE["expires_at"] = now_mono + 120.0
        return result

    body = resp.json()
    raw_items = body.get("metrics") if isinstance(body, dict) else []
    parsed: dict[str, dict[str, Any]] = {}
    if isinstance(raw_items, list):
        for item in raw_items:
            if not isinstance(item, dict):
                continue
            mid = str(item.get("id") or "")
            if not mid:
                continue
            parsed[mid] = {
                "name": item.get("name"),
                "description": item.get("description"),
                "unit": item.get("unit"),
                "period": item.get("period"),
                "value": item.get("value", 0),
                "last_updated_at_iso8601": item.get("last_updated_at_iso8601"),
            }

    result = {
        "connected": True,
        "mode": "live_v2",
        "project_id": REVENUECAT_PROJECT_ID,
        "currency": str((body or {}).get("currency") or "USD"),
        "fetched_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "metrics": parsed,
    }
    _RC_OVERVIEW_CACHE["data"] = result
    _RC_OVERVIEW_CACHE["expires_at"] = now_mono + _RC_OVERVIEW_TTL_SECONDS
    return result
