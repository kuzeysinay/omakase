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
from app.security import _RATE_BUCKETS, verify_firebase_user
from app.services import gemini_service
from main import app


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

        with patch.object(gemini_service, "GEMINI_API_KEY", None), patch.object(
            gemini_service, "genai_client", None
        ):
            for _ in range(20):
                resp = self.client.post(
                    "/feed/stream",
                    json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
                )
                self.assertEqual(resp.status_code, 200)

            limited = self.client.post(
                "/feed/stream",
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

        with patch.object(gemini_service, "GEMINI_API_KEY", None), patch.object(
            gemini_service, "genai_client", None
        ):
            resp = self.client.post(
                "/feed/stream",
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

        with patch.object(gemini_service, "GEMINI_API_KEY", "test-key"), patch.object(
            gemini_service, "genai_client", _FakeClient()
        ):
            resp = self.client.post(
                "/feed/stream",
                json={"interests": ["Cinema"], "seen_count": 0, "language": "en"},
            )

        self.assertEqual(resp.status_code, 200)
        self.assertIn("event: error", resp.text)
        self.assertIn('"code": "content_blocked"', resp.text)
        self.assertNotIn("event: done", resp.text)


if __name__ == "__main__":
    unittest.main()
