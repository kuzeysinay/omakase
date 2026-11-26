"""Tests for the canonical backend error contract and SSE error framing."""

from __future__ import annotations

from io import BytesIO
import os
import sys
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

from fastapi.testclient import TestClient

from app import security
from app.errors import ErrorCode, OmakaseAPIError
from app.security import _RATE_BUCKETS, _RATE_BUCKET_LAST_SEEN, verify_firebase_user
from app.services import access_service, firestore_admin, gemini_service
from main import app

_DEV_HEADERS = {"X-Omakase-Device-Id": "test-device-error-contract-001"}


class _NoopSnap:
    exists = False

    @staticmethod
    def to_dict() -> None:
        return None


class _NoopDocRef:
    def get(self, transaction: object = None) -> _NoopSnap:
        del transaction
        return _NoopSnap()

    def set(self, payload: dict, merge: bool = False) -> None:
        del payload, merge


class _NoopCollection:
    def document(self, doc_id: str) -> _NoopDocRef:
        del doc_id
        return _NoopDocRef()


class _NoopTransaction:
    def set(self, doc_ref: _NoopDocRef, payload: dict, merge: bool = False) -> None:
        del doc_ref, payload, merge


class _NoopFirestore:
    def collection(self, name: str) -> _NoopCollection:
        del name
        return _NoopCollection()

    def execute_fake_transaction(self, fn):
        return fn(_NoopTransaction())


class ErrorContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)
        app.dependency_overrides.clear()
        _RATE_BUCKETS.clear()

    def tearDown(self) -> None:
        app.dependency_overrides.clear()
        _RATE_BUCKETS.clear()

    def test_missing_auth_returns_401_unauthorized_code(self) -> None:
        with patch.object(security, "REQUIRE_AUTH", True):
            resp = self.client.post(
                "/feed/stream",
                json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
            )
        self.assertEqual(resp.status_code, 401)
        data = resp.json()
        self.assertEqual(data["code"], ErrorCode.UNAUTHORIZED)

    def test_rate_limit_returns_429_with_retry_after_header_and_body(self) -> None:
        async def _fake_user() -> str:
            return "uid:test-rate-limit"

        app.dependency_overrides[verify_firebase_user] = _fake_user

        with patch.object(access_service, "get_firestore_client", return_value=_NoopFirestore()), patch.object(
            gemini_service, "GEMINI_API_KEY", None
        ), patch.object(
            gemini_service, "genai_client", None
        ):
            for _ in range(20):
                resp = self.client.post(
                    "/feed/stream",
                    headers=_DEV_HEADERS,
                    json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
                )
                self.assertEqual(resp.status_code, 200)

            limited = self.client.post(
                "/feed/stream",
                headers=_DEV_HEADERS,
                json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
            )

        self.assertEqual(limited.status_code, 429)
        self.assertIn("Retry-After", limited.headers)
        retry_header = int(limited.headers["Retry-After"])
        self.assertGreaterEqual(retry_header, 1)
        payload = limited.json()
        self.assertEqual(payload["code"], ErrorCode.RATE_LIMITED)
        self.assertIsInstance(payload["retry_after"], int)
        self.assertEqual(payload["retry_after"], retry_header)

    def test_blocklisted_interest_returns_422_content_blocked(self) -> None:
        async def _fake_user() -> str:
            return "uid:test-blocklist"

        app.dependency_overrides[verify_firebase_user] = _fake_user

        resp = self.client.post(
            "/feed/stream",
            json={"interests": ["porn"], "seen_count": 0, "language": "en"},
        )
        self.assertEqual(resp.status_code, 422)
        self.assertEqual(resp.json()["code"], ErrorCode.CONTENT_BLOCKED)

    def test_missing_gemini_key_streams_service_unavailable_without_done(self) -> None:
        async def _fake_user() -> str:
            return "uid:test-missing-key"

        app.dependency_overrides[verify_firebase_user] = _fake_user

        with patch.object(access_service, "get_firestore_client", return_value=_NoopFirestore()), patch.object(
            gemini_service, "GEMINI_API_KEY", None
        ), patch.object(
            gemini_service, "genai_client", None
        ):
            resp = self.client.post(
                "/feed/stream",
                headers=_DEV_HEADERS,
                json={"interests": ["Architecture"], "seen_count": 0, "language": "tr"},
            )

        self.assertEqual(resp.status_code, 200)
        body = resp.text
        self.assertIn("event: error", body)
        self.assertIn('"code": "service_unavailable"', body)
        self.assertNotIn("event: done", body)

    def test_letterboxd_404_and_403_return_canonical_codes(self) -> None:
        async def _fake_user() -> str:
            return "uid:test-letterboxd"

        app.dependency_overrides[verify_firebase_user] = _fake_user

        def _raise_404(*_args: object, **_kwargs: object) -> object:
            raise HTTPError(
                url="https://letterboxd.com/missinguser/rss/",
                code=404,
                msg="Not Found",
                hdrs=None,
                fp=BytesIO(b""),
            )

        with patch(
            "app.services.letterboxd_service.urlopen", side_effect=_raise_404
        ):
            resp_404 = self.client.post(
                "/letterboxd/films",
                json={"username": "missinguser", "limit": 10},
            )
        self.assertEqual(resp_404.status_code, 404)
        self.assertEqual(resp_404.json()["code"], ErrorCode.LETTERBOXD_NOT_FOUND)

        def _raise_403(*_args: object, **_kwargs: object) -> object:
            raise HTTPError(
                url="https://letterboxd.com/privateuser/rss/",
                code=403,
                msg="Forbidden",
                hdrs=None,
                fp=BytesIO(b""),
            )

        with patch(
            "app.services.letterboxd_service.urlopen", side_effect=_raise_403
        ):
            resp_403 = self.client.post(
                "/letterboxd/films",
                json={"username": "privateuser", "limit": 10},
            )
        self.assertEqual(resp_403.status_code, 403)
        self.assertEqual(resp_403.json()["code"], ErrorCode.LETTERBOXD_PRIVATE)

    def test_safety_blocked_stream_yields_content_blocked_without_done(self) -> None:
        async def _fake_user() -> str:
            return "uid:test-safety-stream"

        app.dependency_overrides[verify_firebase_user] = _fake_user

        class _FakeCandidate:
            finish_reason = "SAFETY"
            content = None

        class _FakeChunk:
            candidates = [_FakeCandidate()]
            prompt_feedback = None
            text = ""

        class _FakeModels:
            @staticmethod
            def generate_content_stream(**_kwargs: object):
                return iter([_FakeChunk()])

        class _FakeClient:
            models = _FakeModels()

        with patch.object(access_service, "get_firestore_client", return_value=_NoopFirestore()), patch.object(
            gemini_service, "GEMINI_API_KEY", "test-key"
        ), patch.object(
            gemini_service, "genai_client", _FakeClient()
        ):
            resp = self.client.post(
                "/feed/stream",
                headers=_DEV_HEADERS,
                json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
            )

        self.assertEqual(resp.status_code, 200)
        self.assertIn("event: error", resp.text)
        self.assertIn('"code": "content_blocked"', resp.text)
        self.assertNotIn("event: done", resp.text)

    def test_firestore_unavailable_fails_closed_503_and_recovers_after_cooldown(self) -> None:
        async def _fake_user() -> str:
            return "uid:test-fail-closed"

        app.dependency_overrides[verify_firebase_user] = _fake_user
        with patch.object(access_service, "get_firestore_client", return_value=None):
            resp = self.client.post(
                "/feed/stream",
                headers=_DEV_HEADERS,
                json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
            )
        self.assertEqual(resp.status_code, 503)
        self.assertEqual(resp.json()["code"], ErrorCode.SERVICE_UNAVAILABLE)

        # Verify firestore_admin recovers after cooldown expiry rather than staying permanently latched
        orig_client = firestore_admin._firestore_client
        orig_until = firestore_admin._init_failed_until
        try:
            firestore_admin._firestore_client = None
            firestore_admin._init_failed_until = 0.0
            with patch("app.services.firestore_admin.time.monotonic", return_value=100.0), patch(
                "app.services.firestore_admin.firebase_admin._apps", ["app"]
            ), patch(
                "app.services.firestore_admin.firestore.client",
                side_effect=RuntimeError("transient error"),
            ):
                self.assertIsNone(firestore_admin.get_firestore_client())
                self.assertGreater(firestore_admin._init_failed_until, 100.0)

            fake_client = object()
            with patch("app.services.firestore_admin.time.monotonic", return_value=200.0), patch(
                "app.services.firestore_admin.firebase_admin._apps", ["app"]
            ), patch(
                "app.services.firestore_admin.firestore.client",
                return_value=fake_client,
            ):
                self.assertIs(firestore_admin.get_firestore_client(), fake_client)
        finally:
            firestore_admin._firestore_client = orig_client
            firestore_admin._init_failed_until = orig_until

    def test_rate_buckets_prune_expired_keys(self) -> None:
        _RATE_BUCKETS.clear()
        _RATE_BUCKET_LAST_SEEN.clear()
        with patch("app.security.time.monotonic", return_value=1000.0):
            security._LAST_RATE_PRUNE_AT = 0.0
            security._check_rate_limit("uid:stale-user", "feed_stream", max_calls=5)
            self.assertIn("feed_stream:uid:stale-user", _RATE_BUCKETS)

        with patch("app.security.time.monotonic", return_value=1400.0):
            security._check_rate_limit("uid:fresh-user", "feed_stream", max_calls=5)
            self.assertNotIn("feed_stream:uid:stale-user", _RATE_BUCKETS)
            self.assertIn("feed_stream:uid:fresh-user", _RATE_BUCKETS)


if __name__ == "__main__":
    unittest.main()
