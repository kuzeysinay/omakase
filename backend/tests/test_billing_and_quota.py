"""Unit tests for Phase 2 billing sync, webhooks, daily quotas, and share reward."""

from __future__ import annotations

import copy
from datetime import datetime, timedelta, timezone
import os
import sys
import unittest
from unittest.mock import patch

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

from fastapi.testclient import TestClient

from app.errors import ErrorCode
from app.routers import billing as billing_router
from app.security import _RATE_BUCKETS, verify_firebase_user
from app.services import access_service, billing_service, gemini_service
from main import app


class _FakeSnap:
    def __init__(self, data: dict | None) -> None:
        self._data = copy.deepcopy(data) if data is not None else None

    @property
    def exists(self) -> bool:
        return self._data is not None

    def to_dict(self) -> dict | None:
        return copy.deepcopy(self._data)


class _FakeTransaction:
    def __init__(self, db: _FakeFirestore) -> None:
        self._db = db

    def set(self, doc_ref: _FakeDocRef, payload: dict, merge: bool = False) -> None:
        doc_ref.set(payload, merge=merge)


class _FakeDocRef:
    def __init__(self, store: dict, col_name: str, doc_id: str) -> None:
        self._store = store
        self._col_name = col_name
        self._doc_id = doc_id

    def get(self, transaction: object = None) -> _FakeSnap:
        del transaction
        col = self._store.get(self._col_name, {})
        return _FakeSnap(col.get(self._doc_id))

    def set(self, payload: dict, merge: bool = False) -> None:
        col = self._store.setdefault(self._col_name, {})
        if merge and self._doc_id in col:
            merged = copy.deepcopy(col[self._doc_id])
            merged.update(copy.deepcopy(payload))
            col[self._doc_id] = merged
        else:
            col[self._doc_id] = copy.deepcopy(payload)


class _FakeCollection:
    def __init__(self, store: dict, name: str) -> None:
        self._store = store
        self._name = name

    def document(self, doc_id: str) -> _FakeDocRef:
        return _FakeDocRef(self._store, self._name, doc_id)


class _FakeFirestore:
    def __init__(self) -> None:
        self.store: dict[str, dict[str, dict]] = {}

    def collection(self, name: str) -> _FakeCollection:
        return _FakeCollection(self.store, name)

    def execute_fake_transaction(self, update_fn):
        return update_fn(_FakeTransaction(self))


class _FakeStreamChunk:
    def __init__(self, text: str) -> None:
        self.text = text
        self.candidates = []


class _FakeModels:
    @staticmethod
    def generate_content_stream(**_kwargs: object):
        return iter(
            [
                _FakeStreamChunk("TITLE: Test Dish\nTAGS: Film, Art\n"),
                _FakeStreamChunk("A crisp cultural story for testing."),
            ]
        )


class _FakeClient:
    models = _FakeModels()


class BillingAndQuotaTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)
        self.fake_db = _FakeFirestore()
        app.dependency_overrides.clear()
        _RATE_BUCKETS.clear()

        async def _fake_user() -> str:
            return "uid:user-123"

        app.dependency_overrides[verify_firebase_user] = _fake_user

    def tearDown(self) -> None:
        app.dependency_overrides.clear()
        _RATE_BUCKETS.clear()

    def test_free_user_5_plates_quota_then_402(self) -> None:
        with patch.object(access_service, "get_firestore_client", return_value=self.fake_db), patch.object(
            gemini_service, "GEMINI_API_KEY", "test-key"
        ), patch.object(gemini_service, "genai_client", _FakeClient()), patch.object(
            gemini_service, "_TOKEN_DRIP_DELAY", 0.0
        ):
            for i in range(3):
                resp = self.client.post(
                    "/feed/stream",
                    json={
                        "interests": ["Cinema"],
                        "seen_count": i,
                        "language": "en",
                        "timezone": "Europe/Istanbul",
                    },
                )
                self.assertEqual(resp.status_code, 200)
                self.assertIn("event: done", resp.text)
                self.assertIn('"access":', resp.text)

            fourth = self.client.post(
                "/feed/stream",
                json={
                    "interests": ["Cinema"],
                    "seen_count": 3,
                    "language": "en",
                    "timezone": "Europe/Istanbul",
                },
            )
        self.assertEqual(fourth.status_code, 402)
        body = fourth.json()
        self.assertEqual(body["code"], ErrorCode.QUOTA_EXCEEDED)
        self.assertEqual(body["kind"], "plate")
        self.assertIn("resets_at", body)
        self.assertEqual(body["access"]["plates_remaining"], 0)

    def test_failed_stream_does_not_consume_quota(self) -> None:
        with patch.object(access_service, "get_firestore_client", return_value=self.fake_db), patch.object(
            gemini_service, "GEMINI_API_KEY", None
        ), patch.object(gemini_service, "genai_client", None):
            resp = self.client.post(
                "/feed/stream",
                json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
            )
            self.assertEqual(resp.status_code, 200)
            self.assertIn("event: error", resp.text)

            status = self.client.get("/billing/status")
        self.assertEqual(status.status_code, 200)
        self.assertEqual(status.json()["plates_used"], 0)
        self.assertEqual(status.json()["plates_remaining"], 3)

    def test_deep_dive_quota_and_share_bonus_once_per_day(self) -> None:
        with patch.object(access_service, "get_firestore_client", return_value=self.fake_db), patch.object(
            gemini_service, "GEMINI_API_KEY", "test-key"
        ), patch.object(gemini_service, "genai_client", _FakeClient()), patch.object(
            gemini_service, "_TOKEN_DRIP_DELAY", 0.0
        ):
            first = self.client.post(
                "/feed/deep-dive",
                json={
                    "original_title": "Test Dish",
                    "original_text": "Original body text.",
                    "interests": ["Cinema"],
                    "language": "en",
                    "timezone": "UTC",
                },
            )
            self.assertEqual(first.status_code, 200)
            self.assertIn("event: done", first.text)

            second = self.client.post(
                "/feed/deep-dive",
                json={
                    "original_title": "Test Dish",
                    "original_text": "Original body text.",
                    "interests": ["Cinema"],
                    "language": "en",
                    "timezone": "UTC",
                },
            )
            self.assertEqual(second.status_code, 402)
            self.assertEqual(second.json()["code"], ErrorCode.QUOTA_EXCEEDED)
            self.assertEqual(second.json()["kind"], "deep_dive")
            self.assertTrue(second.json()["access"]["can_claim_share_bonus"])

            reward1 = self.client.post("/feed/reward-share", json={"timezone": "UTC"})
            self.assertEqual(reward1.status_code, 200)
            r1 = reward1.json()
            self.assertTrue(r1["granted"])
            self.assertEqual(r1["bonus_added"], 1)
            self.assertEqual(r1["access"]["deep_dives_limit"], 2)
            self.assertEqual(r1["access"]["deep_dives_remaining"], 1)
            self.assertFalse(r1["access"]["can_claim_share_bonus"])

            reward2 = self.client.post("/feed/reward-share", json={"timezone": "UTC"})
            self.assertEqual(reward2.status_code, 200)
            self.assertFalse(reward2.json()["granted"])
            self.assertEqual(reward2.json()["bonus_added"], 0)

            third = self.client.post(
                "/feed/deep-dive",
                json={
                    "original_title": "Test Dish",
                    "original_text": "Original body text.",
                    "interests": ["Cinema"],
                    "language": "en",
                    "timezone": "UTC",
                },
            )
            self.assertEqual(third.status_code, 200)

    def test_pro_user_bypasses_free_caps(self) -> None:
        future_iso = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat().replace("+00:00", "Z")
        self.fake_db.collection("entitlements").document("user-123").set(
            {
                "isPro": True,
                "status": "active",
                "productId": "omakase.pro.yearly",
                "expiresAt": future_iso,
                "willRenew": True,
            }
        )
        with patch.object(access_service, "get_firestore_client", return_value=self.fake_db), patch.object(
            gemini_service, "GEMINI_API_KEY", "test-key"
        ), patch.object(gemini_service, "genai_client", _FakeClient()), patch.object(
            gemini_service, "_TOKEN_DRIP_DELAY", 0.0
        ):
            for i in range(6):
                resp = self.client.post(
                    "/feed/stream",
                    json={"interests": ["Cinema"], "seen_count": i, "language": "en"},
                )
                self.assertEqual(resp.status_code, 200)
            status = self.client.get("/billing/status")
        self.assertTrue(status.json()["is_pro"])
        self.assertEqual(status.json()["plates_limit"], 100)
        self.assertEqual(status.json()["plates_used"], 6)

    def test_revenuecat_webhook_auth_and_lifecycle(self) -> None:
        future_ms = int((datetime.now(timezone.utc) + timedelta(days=7)).timestamp() * 1000)
        past_ms = int((datetime.now(timezone.utc) - timedelta(days=1)).timestamp() * 1000)

        with patch.object(access_service, "get_firestore_client", return_value=self.fake_db), patch.object(
            billing_router, "REVENUECAT_WEBHOOK_SECRET", "test-webhook-secret"
        ):
            bad = self.client.post(
                "/billing/revenuecat-webhook",
                headers={"Authorization": "Bearer wrong"},
                json={"event": {"type": "TEST"}},
            )
            self.assertEqual(bad.status_code, 401)

            init_resp = self.client.post(
                "/billing/revenuecat-webhook",
                headers={"Authorization": "Bearer test-webhook-secret"},
                json={
                    "event": {
                        "type": "INITIAL_PURCHASE",
                        "app_user_id": "user-123",
                        "entitlement_ids": ["pro"],
                        "product_id": "omakase.pro.yearly",
                        "period_type": "TRIAL",
                        "expiration_at_ms": future_ms,
                    }
                },
            )
            self.assertEqual(init_resp.status_code, 200)
            status1 = self.client.get("/billing/status").json()
            self.assertTrue(status1["is_pro"])
            self.assertEqual(status1["status"], "trial")
            self.assertTrue(status1["will_renew"])

            cancel_resp = self.client.post(
                "/billing/revenuecat-webhook",
                headers={"Authorization": "test-webhook-secret"},
                json={
                    "event": {
                        "type": "CANCELLATION",
                        "app_user_id": "user-123",
                        "entitlement_ids": ["pro"],
                        "product_id": "omakase.pro.yearly",
                        "period_type": "TRIAL",
                        "expiration_at_ms": future_ms,
                    }
                },
            )
            self.assertEqual(cancel_resp.status_code, 200)
            status2 = self.client.get("/billing/status").json()
            self.assertTrue(status2["is_pro"])
            self.assertFalse(status2["will_renew"])

            exp_resp = self.client.post(
                "/billing/revenuecat-webhook",
                headers={"Authorization": "Bearer test-webhook-secret"},
                json={
                    "event": {
                        "type": "EXPIRATION",
                        "app_user_id": "user-123",
                        "entitlement_ids": ["pro"],
                        "product_id": "omakase.pro.yearly",
                        "expiration_at_ms": past_ms,
                    }
                },
            )
            self.assertEqual(exp_resp.status_code, 200)
            status3 = self.client.get("/billing/status").json()
            self.assertFalse(status3["is_pro"])
            self.assertEqual(status3["status"], "expired")

    def test_billing_sync_persists_entitlement(self) -> None:
        future_iso = (datetime.now(timezone.utc) + timedelta(days=365)).isoformat().replace("+00:00", "Z")

        class _FakeHTTPResponse:
            status_code = 200

            @staticmethod
            def json() -> dict:
                return {
                    "subscriber": {
                        "entitlements": {
                            "pro": {
                                "expires_date": future_iso,
                                "product_identifier": "omakase.pro.yearly",
                            }
                        },
                        "subscriptions": {
                            "omakase.pro.yearly": {
                                "period_type": "normal",
                                "billing_issues_detected_at": None,
                                "unsubscribe_detected_at": None,
                            }
                        },
                    }
                }

        class _FakeAsyncClient:
            def __init__(self, **_kwargs: object) -> None:
                pass

            async def __aenter__(self):
                return self

            async def __aexit__(self, *_args: object) -> None:
                return None

            async def get(self, *_args: object, **_kwargs: object):
                return _FakeHTTPResponse()

        with patch.object(access_service, "get_firestore_client", return_value=self.fake_db), patch.object(
            billing_service, "REVENUECAT_SECRET_API_KEY", "sk_test"
        ), patch("app.services.billing_service.httpx.AsyncClient", _FakeAsyncClient):
            resp = self.client.post("/billing/sync", json={"timezone": "Europe/Istanbul"})

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertTrue(body["is_pro"])
        self.assertEqual(body["status"], "active")
        self.assertEqual(body["product_id"], "omakase.pro.yearly")


if __name__ == "__main__":
    unittest.main()
