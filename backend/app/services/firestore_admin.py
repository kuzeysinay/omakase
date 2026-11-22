"""Lazy Firebase Admin SDK / Firestore client singleton."""

from __future__ import annotations

from typing import Any, Optional

import firebase_admin
from firebase_admin import firestore

from app.config import FIREBASE_PROJECT_ID, logger

_firestore_client: Any = None
_init_failed: bool = False


def get_firestore_client() -> Optional[Any]:
    """Return a cached Firestore Admin client, or None if unavailable locally."""
    global _firestore_client, _init_failed
    if _firestore_client is not None:
        return _firestore_client
    if _init_failed:
        return None
    try:
        if not firebase_admin._apps:
            firebase_admin.initialize_app(options={"projectId": FIREBASE_PROJECT_ID})
        _firestore_client = firestore.client()
        return _firestore_client
    except Exception as exc:  # noqa: BLE001
        _init_failed = True
        logger.warning("Firestore Admin client unavailable: %s", exc)
        return None
