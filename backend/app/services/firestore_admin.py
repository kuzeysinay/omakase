"""Lazy Firebase Admin SDK / Firestore client singleton."""

from __future__ import annotations

import time
from typing import Any, Optional

import firebase_admin
from firebase_admin import firestore

from app.config import FIREBASE_PROJECT_ID, logger

_firestore_client: Any = None
_init_failed_until: float = 0.0
_INIT_RETRY_COOLDOWN_SECONDS: float = 30.0


def get_firestore_client() -> Optional[Any]:
    """Return a cached Firestore Admin client, retrying after a cooldown on init failure."""
    global _firestore_client, _init_failed_until
    if _firestore_client is not None:
        return _firestore_client
    now = time.monotonic()
    if now < _init_failed_until:
        return None
    try:
        if not firebase_admin._apps:
            firebase_admin.initialize_app(options={"projectId": FIREBASE_PROJECT_ID})
        _firestore_client = firestore.client()
        _init_failed_until = 0.0
        return _firestore_client
    except Exception as exc:  # noqa: BLE001
        _init_failed_until = now + _INIT_RETRY_COOLDOWN_SECONDS
        logger.warning("Firestore Admin client unavailable: %s", exc)
        return None
