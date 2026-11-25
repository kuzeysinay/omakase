"""Server-enforced entitlements, daily usage tracking, and share reward service."""

from __future__ import annotations

import asyncio
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from firebase_admin import firestore

from app.config import (
    FREE_DAILY_DEEP_DIVES,
    FREE_DAILY_LETTERBOXD_PLATES,
    FREE_DAILY_PLATES,
    FREE_DAILY_SUGGESTIONS,
    PRO_DAILY_DEEP_DIVES,
    PRO_DAILY_LETTERBOXD_PLATES,
    PRO_DAILY_PLATES,
    PRO_DAILY_SUGGESTIONS,
    SHARE_BONUS_DEEP_DIVES,
    USER_DAILY_PLATES_OVERRIDES,
    logger,
)
from app.errors import ErrorCode, OmakaseAPIError
from app.services.firestore_admin import get_firestore_client

_EXPIRY_GRACE_SECONDS = 300


def parse_iso_datetime(raw: Optional[str]) -> Optional[datetime]:
    """Parse an ISO-8601 timestamp string into a timezone-aware UTC datetime."""
    if not raw or not isinstance(raw, str):
        return None
    cleaned = raw.strip()
    if not cleaned:
        return None
    if cleaned.endswith("Z"):
        cleaned = cleaned[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(cleaned)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def resolve_user_day(tz_name: Optional[str]) -> tuple[str, str, str]:
    """Resolve user's local day key (`YYYYMMDD`), validated IANA zone, and UTC reset timestamp."""
    resolved_tz = "UTC"
    zone: ZoneInfo
    if tz_name and isinstance(tz_name, str) and tz_name.strip():
        candidate = tz_name.strip()
        try:
            zone = ZoneInfo(candidate)
            resolved_tz = candidate
        except ZoneInfoNotFoundError:
            zone = ZoneInfo("UTC")
    else:
        zone = ZoneInfo("UTC")

    now_utc = datetime.now(timezone.utc)
    local_now = now_utc.astimezone(zone)
    day_key = local_now.strftime("%Y%m%d")
    next_midnight_local = datetime(
        local_now.year,
        local_now.month,
        local_now.day,
        tzinfo=zone,
    ) + timedelta(days=1)
    resets_at = next_midnight_local.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
    return day_key, resolved_tz, resets_at


def _default_entitlement() -> dict[str, Any]:
    return {
        "is_pro": False,
        "status": "free",
        "product_id": None,
        "expires_at": None,
        "will_renew": False,
        "source": "default",
    }


def _default_usage() -> dict[str, Any]:
    return {
        "plates_used": 0,
        "letterboxd_plates_used": 0,
        "deep_dives_used": 0,
        "suggestions_used": 0,
        "bonus_deep_dives": 0,
        "share_bonus_claimed": False,
    }


def _normalize_entitlement_doc(data: Optional[dict[str, Any]]) -> dict[str, Any]:
    if not data:
        return _default_entitlement()
    is_pro = bool(data.get("isPro", data.get("is_pro", False)))
    status = str(data.get("status") or ("active" if is_pro else "free"))
    product_id = data.get("productId", data.get("product_id"))
    expires_raw = data.get("expiresAt", data.get("expires_at"))
    expires_at = str(expires_raw) if expires_raw else None
    will_renew = bool(data.get("willRenew", data.get("will_renew", False)))
    source = str(data.get("source") or "firestore")

    if is_pro and expires_at:
        exp_dt = parse_iso_datetime(expires_at)
        if exp_dt is not None:
            now_utc = datetime.now(timezone.utc)
            if exp_dt + timedelta(seconds=_EXPIRY_GRACE_SECONDS) < now_utc:
                is_pro = False
                status = "expired"
                will_renew = False

    return {
        "is_pro": is_pro,
        "status": status,
        "product_id": str(product_id) if product_id else None,
        "expires_at": expires_at,
        "will_renew": will_renew,
        "source": source,
    }


def _normalize_usage_doc(data: Optional[dict[str, Any]]) -> dict[str, Any]:
    if not data:
        return _default_usage()
    return {
        "plates_used": max(0, int(data.get("platesUsed", data.get("plates_used", 0)) or 0)),
        "letterboxd_plates_used": max(
            0,
            int(data.get("letterboxdPlatesUsed", data.get("letterboxd_plates_used", 0)) or 0),
        ),
        "deep_dives_used": max(
            0, int(data.get("deepDivesUsed", data.get("deep_dives_used", 0)) or 0)
        ),
        "suggestions_used": max(
            0, int(data.get("suggestionsUsed", data.get("suggestions_used", 0)) or 0)
        ),
        "bonus_deep_dives": max(
            0, int(data.get("bonusDeepDives", data.get("bonus_deep_dives", 0)) or 0)
        ),
        "share_bonus_claimed": bool(
            data.get("shareBonusClaimed", data.get("share_bonus_claimed", False))
        ),
    }


def get_entitlement(uid: str) -> dict[str, Any]:
    """Read the user's entitlement from `entitlements/{uid}`."""
    db = get_firestore_client()
    if db is None:
        return _default_entitlement()
    snap = db.collection("entitlements").document(uid).get()
    if not snap.exists:
        return _default_entitlement()
    return _normalize_entitlement_doc(snap.to_dict())


def set_entitlement(uid: str, data: dict[str, Any]) -> dict[str, Any]:
    """Persist server-verified entitlement state to `entitlements/{uid}`."""
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    payload = {
        "isPro": bool(data.get("is_pro", False)),
        "status": str(data.get("status") or ("active" if data.get("is_pro") else "free")),
        "productId": data.get("product_id"),
        "expiresAt": data.get("expires_at"),
        "willRenew": bool(data.get("will_renew", False)),
        "source": str(data.get("source") or "revenuecat"),
        "updatedAt": now_iso,
    }
    db = get_firestore_client()
    if db is not None:
        db.collection("entitlements").document(uid).set(payload, merge=True)
    return _normalize_entitlement_doc(payload)


def _hash_device_id(device_id: Optional[str]) -> Optional[str]:
    """One-way SHA-256 hash of an anonymous installation ID for anti-abuse quota enforcement."""
    if not device_id:
        return None
    cleaned = device_id.strip()
    if len(cleaned) < 8 or len(cleaned) > 128:
        return None
    return hashlib.sha256(f"omakase-device-quota:{cleaned}".encode("utf-8")).hexdigest()[:32]


def get_usage(uid: str, day_key: str) -> dict[str, Any]:
    """Read the user's daily usage counters from `usage/{uid}_{day_key}`."""
    db = get_firestore_client()
    if db is None:
        return _default_usage()
    doc_id = f"{uid}_{day_key}"
    snap = db.collection("usage").document(doc_id).get()
    if not snap.exists:
        return _default_usage()
    return _normalize_usage_doc(snap.to_dict())


def get_device_usage(device_hash: Optional[str], day_key: str) -> dict[str, Any]:
    """Read anonymous device-level daily usage counters from `device_usage/{device_hash}_{day_key}`."""
    if not device_hash:
        return _default_usage()
    db = get_firestore_client()
    if db is None:
        return _default_usage()
    snap = db.collection("device_usage").document(f"{device_hash}_{day_key}").get()
    if not snap.exists:
        return _default_usage()
    return _normalize_usage_doc(snap.to_dict())


def _merge_usage(user_usage: dict[str, Any], device_usage: dict[str, Any]) -> dict[str, Any]:
    return {
        "plates_used": max(int(user_usage["plates_used"]), int(device_usage["plates_used"])),
        "letterboxd_plates_used": max(
            int(user_usage["letterboxd_plates_used"]),
            int(device_usage["letterboxd_plates_used"]),
        ),
        "deep_dives_used": max(int(user_usage["deep_dives_used"]), int(device_usage["deep_dives_used"])),
        "suggestions_used": max(int(user_usage["suggestions_used"]), int(device_usage["suggestions_used"])),
        "bonus_deep_dives": max(int(user_usage["bonus_deep_dives"]), int(device_usage["bonus_deep_dives"])),
        "share_bonus_claimed": bool(user_usage["share_bonus_claimed"]) or bool(device_usage["share_bonus_claimed"]),
    }


def _assemble_snapshot(
    entitlement: dict[str, Any],
    usage: dict[str, Any],
    day_key: str,
    resolved_tz: str,
    resets_at: str,
    uid: Optional[str] = None,
) -> dict[str, Any]:
    is_pro = bool(entitlement["is_pro"])
    if is_pro:
        plates_limit = PRO_DAILY_PLATES
    else:
        plates_limit = USER_DAILY_PLATES_OVERRIDES.get(uid or "", FREE_DAILY_PLATES)
    letterboxd_plates_limit = (
        PRO_DAILY_LETTERBOXD_PLATES if is_pro else FREE_DAILY_LETTERBOXD_PLATES
    )
    deep_dives_limit = (
        PRO_DAILY_DEEP_DIVES
        if is_pro
        else FREE_DAILY_DEEP_DIVES + int(usage["bonus_deep_dives"])
    )
    suggestions_limit = PRO_DAILY_SUGGESTIONS if is_pro else FREE_DAILY_SUGGESTIONS

    plates_used = int(usage["plates_used"])
    letterboxd_plates_used = int(usage["letterboxd_plates_used"])
    deep_dives_used = int(usage["deep_dives_used"])
    suggestions_used = int(usage["suggestions_used"])
    share_bonus_claimed = bool(usage["share_bonus_claimed"])

    return {
        "is_pro": is_pro,
        "status": entitlement["status"],
        "product_id": entitlement["product_id"],
        "expires_at": entitlement["expires_at"],
        "will_renew": entitlement["will_renew"],
        "day_key": day_key,
        "timezone": resolved_tz,
        "resets_at": resets_at,
        "plates_used": plates_used,
        "plates_limit": plates_limit,
        "plates_remaining": max(0, plates_limit - plates_used),
        "letterboxd_plates_used": letterboxd_plates_used,
        "letterboxd_plates_limit": letterboxd_plates_limit,
        "letterboxd_plates_remaining": max(0, letterboxd_plates_limit - letterboxd_plates_used),
        "deep_dives_used": deep_dives_used,
        "deep_dives_limit": deep_dives_limit,
        "deep_dives_remaining": max(0, deep_dives_limit - deep_dives_used),
        "suggestions_used": suggestions_used,
        "suggestions_limit": suggestions_limit,
        "suggestions_remaining": max(0, suggestions_limit - suggestions_used),
        "share_bonus_claimed": share_bonus_claimed,
        "can_claim_share_bonus": (not is_pro) and (not share_bonus_claimed),
    }


def build_access_snapshot(
    uid: str,
    tz_name: Optional[str],
    device_id: Optional[str] = None,
) -> dict[str, Any]:
    """Build the full entitlement + daily quota snapshot for a user (and device for free tier)."""
    day_key, resolved_tz, resets_at = resolve_user_day(tz_name)
    entitlement = get_entitlement(uid)
    usage = get_usage(uid, day_key)
    if not entitlement["is_pro"]:
        device_hash = _hash_device_id(device_id)
        if device_hash:
            usage = _merge_usage(usage, get_device_usage(device_hash, day_key))
    return _assemble_snapshot(
        entitlement, usage, day_key, resolved_tz, resets_at, uid=uid
    )


def _execute_transaction(db: Any, update_fn: Callable[[Any], Any]) -> Any:
    if hasattr(db, "execute_fake_transaction"):
        return db.execute_fake_transaction(update_fn)
    tx = db.transaction()

    @firestore.transactional
    def _runner(transaction: Any) -> Any:
        return update_fn(transaction)

    return _runner(tx)


def _check_quota_sync(
    uid: str,
    kind: str,
    tz_name: Optional[str],
    device_id: Optional[str] = None,
) -> dict[str, Any]:
    snapshot = build_access_snapshot(uid, tz_name, device_id=device_id)
    if kind == "plate":
        remaining = snapshot["plates_remaining"]
    elif kind == "letterboxd":
        remaining = snapshot["letterboxd_plates_remaining"]
    elif kind == "deep_dive":
        remaining = snapshot["deep_dives_remaining"]
    elif kind == "suggestion":
        remaining = snapshot["suggestions_remaining"]
    else:
        raise ValueError(f"Unknown quota kind: {kind!r}")

    if remaining <= 0:
        raise OmakaseAPIError(
            status_code=402,
            code=ErrorCode.QUOTA_EXCEEDED,
            detail="Daily limit reached.",
            extra={
                "kind": kind,
                "resets_at": snapshot["resets_at"],
                "access": snapshot,
            },
        )
    return snapshot


async def assert_quota_available(
    uid: Optional[str],
    kind: str,
    tz_name: Optional[str],
    device_id: Optional[str] = None,
) -> dict[str, Any]:
    """Raise 402 `quota_exceeded` if the authenticated user or device has exhausted daily quota."""
    if not uid:
        return {}
    return await asyncio.to_thread(_check_quota_sync, uid, kind, tz_name, device_id)


def _record_usage_sync(
    uid: str,
    kind: str,
    tz_name: Optional[str],
    device_id: Optional[str] = None,
) -> Optional[dict[str, Any]]:
    db = get_firestore_client()
    day_key, resolved_tz, resets_at = resolve_user_day(tz_name)
    entitlement = get_entitlement(uid)
    if db is None:
        return _assemble_snapshot(
            entitlement, _default_usage(), day_key, resolved_tz, resets_at, uid=uid
        )

    field_map = {
        "plate": "platesUsed",
        "letterboxd_plate": "platesUsed",
        "deep_dive": "deepDivesUsed",
        "suggestion": "suggestionsUsed",
    }
    target_field = field_map.get(kind)
    if not target_field:
        return None

    doc_ref = db.collection("usage").document(f"{uid}_{day_key}")
    device_hash = _hash_device_id(device_id)
    device_ref = (
        db.collection("device_usage").document(f"{device_hash}_{day_key}")
        if (device_hash and not entitlement["is_pro"])
        else None
    )
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def _update(transaction: Any) -> dict[str, Any]:
        snap = doc_ref.get(transaction=transaction)
        existing = snap.to_dict() if snap.exists else {}
        usage = _normalize_usage_doc(existing)

        if device_ref is not None:
            dev_snap = device_ref.get(transaction=transaction)
            dev_existing = dev_snap.to_dict() if dev_snap.exists else {}
            usage = _merge_usage(usage, _normalize_usage_doc(dev_existing))

        updates: dict[str, Any] = {"updatedAt": now_iso}
        if kind == "letterboxd_plate":
            usage["plates_used"] += 1
            usage["letterboxd_plates_used"] += 1
            updates["platesUsed"] = usage["plates_used"]
            updates["letterboxdPlatesUsed"] = usage["letterboxd_plates_used"]
        elif kind == "plate":
            usage["plates_used"] += 1
            updates["platesUsed"] = usage["plates_used"]
        elif kind == "deep_dive":
            usage["deep_dives_used"] += 1
            updates["deepDivesUsed"] = usage["deep_dives_used"]
        else:
            usage["suggestions_used"] += 1
            updates["suggestionsUsed"] = usage["suggestions_used"]

        transaction.set(
            doc_ref,
            {
                "uid": uid,
                "dayKey": day_key,
                **updates,
            },
            merge=True,
        )
        if device_ref is not None:
            transaction.set(
                device_ref,
                {
                    "deviceHash": device_hash,
                    "dayKey": day_key,
                    **updates,
                },
                merge=True,
            )
        return usage

    updated_usage = _execute_transaction(db, _update)
    return _assemble_snapshot(
        entitlement, updated_usage, day_key, resolved_tz, resets_at, uid=uid
    )


async def record_quota_usage(
    uid: Optional[str],
    kind: str,
    tz_name: Optional[str],
    device_id: Optional[str] = None,
) -> Optional[dict[str, Any]]:
    """Atomically increment daily usage for `uid` (and device for free tier) after generation."""
    if not uid:
        return None
    try:
        return await asyncio.to_thread(_record_usage_sync, uid, kind, tz_name, device_id)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to record usage (%s) for %s: %s", kind, uid, exc)
        return None


def _claim_share_bonus_sync(
    uid: str,
    tz_name: Optional[str],
    device_id: Optional[str] = None,
) -> dict[str, Any]:
    day_key, resolved_tz, resets_at = resolve_user_day(tz_name)
    entitlement = get_entitlement(uid)
    db = get_firestore_client()
    if db is None:
        snapshot = _assemble_snapshot(
            entitlement, _default_usage(), day_key, resolved_tz, resets_at, uid=uid
        )
        return {"granted": False, "bonus_added": 0, "access": snapshot}

    if entitlement["is_pro"]:
        usage = get_usage(uid, day_key)
        snapshot = _assemble_snapshot(
            entitlement, usage, day_key, resolved_tz, resets_at, uid=uid
        )
        return {"granted": False, "bonus_added": 0, "access": snapshot}

    doc_ref = db.collection("usage").document(f"{uid}_{day_key}")
    device_hash = _hash_device_id(device_id)
    device_ref = (
        db.collection("device_usage").document(f"{device_hash}_{day_key}")
        if device_hash
        else None
    )
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    def _update(transaction: Any) -> tuple[bool, dict[str, Any]]:
        snap = doc_ref.get(transaction=transaction)
        existing = snap.to_dict() if snap.exists else {}
        usage = _normalize_usage_doc(existing)

        if device_ref is not None:
            dev_snap = device_ref.get(transaction=transaction)
            dev_existing = dev_snap.to_dict() if dev_snap.exists else {}
            usage = _merge_usage(usage, _normalize_usage_doc(dev_existing))

        if usage["share_bonus_claimed"]:
            return False, usage

        usage["share_bonus_claimed"] = True
        usage["bonus_deep_dives"] += SHARE_BONUS_DEEP_DIVES
        transaction.set(
            doc_ref,
            {
                "uid": uid,
                "dayKey": day_key,
                "shareBonusClaimed": True,
                "bonusDeepDives": usage["bonus_deep_dives"],
                "updatedAt": now_iso,
            },
            merge=True,
        )
        if device_ref is not None:
            transaction.set(
                device_ref,
                {
                    "deviceHash": device_hash,
                    "dayKey": day_key,
                    "shareBonusClaimed": True,
                    "bonusDeepDives": usage["bonus_deep_dives"],
                    "updatedAt": now_iso,
                },
                merge=True,
            )
        return True, usage

    granted, updated_usage = _execute_transaction(db, _update)
    snapshot = _assemble_snapshot(
        entitlement, updated_usage, day_key, resolved_tz, resets_at, uid=uid
    )
    return {
        "granted": granted,
        "bonus_added": SHARE_BONUS_DEEP_DIVES if granted else 0,
        "access": snapshot,
    }


async def claim_share_bonus(
    uid: str,
    tz_name: Optional[str],
    device_id: Optional[str] = None,
) -> dict[str, Any]:
    """Grant once-per-day +1/+2 Deep Dive bonus when a free user shares a post."""
    return await asyncio.to_thread(_claim_share_bonus_sync, uid, tz_name, device_id)
