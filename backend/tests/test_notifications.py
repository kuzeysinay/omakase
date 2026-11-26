"""Unit tests for Phase 3 social notifications, quiet hours, cooldown grouping, and digest queue."""

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
from firebase_admin import messaging

from app.routers import notifications as notifications_router
from app.schemas import SocialNotificationEventRequest
from app.security import _RATE_BUCKETS, verify_firebase_user
from app.services import notification_service
from main import app


class _FakeSnap:
    def __init__(self, doc_id: str, data: dict | None, ref: _FakeDocRef | None = None) -> None:
        self.id = doc_id
        self._data = copy.deepcopy(data) if data is not None else None
        self.reference = ref

    @property
    def exists(self) -> bool:
        return self._data is not None

    def to_dict(self) -> dict | None:
        return copy.deepcopy(self._data)


class _FakeQuery:
    def __init__(self, collection: _FakeCollection, filters: list[tuple[str, str, object]] | None = None, limit_val: int | None = None) -> None:
        self._collection = collection
        self._filters = filters or []
        self._limit = limit_val

    def where(self, field: str, op: str, value: object) -> _FakeQuery:
        return _FakeQuery(self._collection, [*self._filters, (field, op, value)], self._limit)

    def limit(self, count: int) -> _FakeQuery:
        return _FakeQuery(self._collection, self._filters, count)

    def stream(self):
        docs = self._collection._all_docs()
        matched = []
        for snap in docs:
            data = snap.to_dict() or {}
            ok = True
            for field, op, value in self._filters:
                actual = data.get(field)
                if op == "==":
                    ok = actual == value
                elif op == "<=":
                    ok = actual is not None and actual <= value
                if not ok:
                    break
            if ok:
                matched.append(snap)
        if self._limit is not None:
            matched = matched[: self._limit]
        return iter(matched)


class _FakeDocRef:
    def __init__(self, store: dict, path: tuple[str, ...]) -> None:
        self._store = store
        self._path = path
        self.id = path[-1]

    def _bucket(self) -> dict[str, dict]:
        col_key = "/".join(self._path[:-1])
        return self._store.setdefault(col_key, {})

    def get(self) -> _FakeSnap:
        return _FakeSnap(self.id, self._bucket().get(self.id), self)

    def set(self, payload: dict, merge: bool = False) -> None:
        bucket = self._bucket()
        if merge and self.id in bucket:
            merged = copy.deepcopy(bucket[self.id])
            merged.update(copy.deepcopy(payload))
            bucket[self.id] = merged
        else:
            bucket[self.id] = copy.deepcopy(payload)

    def delete(self) -> None:
        self._bucket().pop(self.id, None)

    def collection(self, sub_name: str) -> _FakeCollection:
        return _FakeCollection(self._store, (*self._path, sub_name))


class _FakeCollection:
    def __init__(self, store: dict, path: tuple[str, ...]) -> None:
        self._store = store
        self._path = path

    def document(self, doc_id: str) -> _FakeDocRef:
        return _FakeDocRef(self._store, (*self._path, doc_id))

    def where(self, field: str, op: str, value: object) -> _FakeQuery:
        return _FakeQuery(self, [(field, op, value)])

    def _all_docs(self) -> list[_FakeSnap]:
        col_key = "/".join(self._path)
        bucket = self._store.get(col_key, {})
        return [
            _FakeSnap(doc_id, data, _FakeDocRef(self._store, (*self._path, doc_id)))
            for doc_id, data in list(bucket.items())
        ]

    def stream(self):
        return iter(self._all_docs())


class _FakeFirestore:
    def __init__(self) -> None:
        self.store: dict[str, dict[str, dict]] = {}

    def collection(self, name: str) -> _FakeCollection:
        return _FakeCollection(self.store, (name,))


class _FakeSendResp:
    def __init__(self, success: bool, exception: Exception | None = None) -> None:
        self.success = success
        self.exception = exception


class _FakeBatchResp:
    def __init__(self, responses: list[_FakeSendResp]) -> None:
        self.responses = responses


class NotificationServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)
        self.fake_db = _FakeFirestore()
        self.sent_messages: list[messaging.MulticastMessage] = []
        app.dependency_overrides.clear()
        _RATE_BUCKETS.clear()

        async def _fake_user() -> str:
            return "uid:actor-1"

        app.dependency_overrides[verify_firebase_user] = _fake_user

        # Seed post, author/actor profiles, comments, reactions, and recipient device + prefs
        self.fake_db.collection("shared_posts").document("post-1").set(
            {"authorId": "recipient-1", "title": "Cinema"}
        )
        self.fake_db.collection("users").document("actor-1").set({"username": "Ada"})
        self.fake_db.collection("users").document("actor-2").set({"username": "Ece"})
        self.fake_db.collection("users").document("actor-3").set({"username": "Can"})
        self.fake_db.collection("shared_posts").document("post-1").collection("comments").document("c-1").set(
            {"authorId": "actor-1", "text": "Harika yazı"}
        )
        self.fake_db.collection("shared_posts").document("post-1").collection("comments").document("c-2").set(
            {"authorId": "actor-2", "text": "Güzelmiş"}
        )
        self.fake_db.collection("shared_posts").document("post-1").collection("comments").document("c-3").set(
            {"authorId": "actor-3", "text": "Katılıyorum"}
        )
        self.fake_db.collection("shared_posts").document("post-1").collection("reactions").document("actor-2").set(
            {"emoji": "✨"}
        )
        self.fake_db.collection("users").document("recipient-1").collection("notification_prefs").document("settings").set(
            {
                "commentPushEnabled": True,
                "dailyDigestEnabled": True,
                "timezone": "Europe/Istanbul",
                "language": "tr",
            }
        )
        self.fake_db.collection("users").document("recipient-1").collection("devices").document("dev-1").set(
            {"fcmToken": "valid-token-1", "platform": "ios"}
        )

    def tearDown(self) -> None:
        app.dependency_overrides.clear()
        _RATE_BUCKETS.clear()

    def _fake_send(self, message: messaging.MulticastMessage):
        self.sent_messages.append(message)
        return _FakeBatchResp([_FakeSendResp(True) for _ in message.tokens])

    def test_quiet_hours_and_0830_deferral_in_istanbul(self) -> None:
        # 20:30 UTC == 23:30 UTC+3 (Europe/Istanbul) -> quiet hours
        now_utc = datetime(2026, 11, 22, 20, 30, tzinfo=timezone.utc)
        deliver = notification_service.next_quiet_hours_delivery_utc(now_utc, "Europe/Istanbul")
        # Next 08:30 Istanbul on Nov 23 is 05:30 UTC
        self.assertEqual(deliver, datetime(2026, 11, 23, 5, 30, tzinfo=timezone.utc))

    def test_self_and_blocked_events_are_ignored(self) -> None:
        now = datetime(2026, 11, 22, 11, 0, tzinfo=timezone.utc)  # 14:00 Istanbul
        with patch.object(notification_service, "get_firestore_client", return_value=self.fake_db):
            # Self comment
            self.fake_db.collection("shared_posts").document("post-1").collection("comments").document("c-self").set(
                {"authorId": "recipient-1", "text": "Hi"}
            )
            self_res = notification_service.record_social_event(
                "recipient-1",
                SocialNotificationEventRequest(event_type="comment", post_id="post-1", comment_id="c-self"),
                now_utc=now,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(self_res["reason"], "self")

            # Blocked actor
            self.fake_db.collection("users").document("recipient-1").collection("blocked_users").document("actor-1").set(
                {"blockedUid": "actor-1"}
            )
            blocked_res = notification_service.record_social_event(
                "actor-1",
                SocialNotificationEventRequest(event_type="comment", post_id="post-1", comment_id="c-1"),
                now_utc=now,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(blocked_res["reason"], "blocked")
            self.assertEqual(len(self.sent_messages), 0)

    def test_forged_comment_reaction_and_spoofed_actor_name_blocked(self) -> None:
        now = datetime(2026, 11, 22, 11, 0, tzinfo=timezone.utc)
        with patch.object(notification_service, "get_firestore_client", return_value=self.fake_db):
            # Missing comment doc -> ignored
            forged_c = notification_service.record_social_event(
                "actor-1",
                SocialNotificationEventRequest(
                    event_type="comment",
                    post_id="post-1",
                    comment_id="nonexistent",
                    comment_preview="Phishing link",
                ),
                now_utc=now,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(forged_c["reason"], "target_not_found")

            # Spoofed preview & actor_name are ignored in favor of Firestore docs
            real_c = notification_service.record_social_event(
                "actor-1",
                SocialNotificationEventRequest(
                    event_type="comment",
                    post_id="post-1",
                    comment_id="c-1",
                    actor_name="Omakase Support",
                    comment_preview="Spoofed text",
                ),
                now_utc=now,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(real_c["status"], "sent")
            self.assertIn("Ada", self.sent_messages[0].notification.title)
            self.assertIn("Harika yazı", self.sent_messages[0].notification.body)
            self.assertNotIn("Spoofed text", self.sent_messages[0].notification.body)

            # Missing reaction doc -> ignored
            forged_r = notification_service.record_social_event(
                "actor-1",
                SocialNotificationEventRequest(event_type="reaction", post_id="post-1"),
                now_utc=now,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(forged_r["reason"], "target_not_found")

            # Duplicate reaction by actor-2 does not inflate reactionsCount
            notification_service.record_social_event(
                "actor-2",
                SocialNotificationEventRequest(event_type="reaction", post_id="post-1"),
                now_utc=now,
                multicast_sender=self._fake_send,
            )
            notification_service.record_social_event(
                "actor-2",
                SocialNotificationEventRequest(event_type="reaction", post_id="post-1"),
                now_utc=now + timedelta(minutes=1),
                multicast_sender=self._fake_send,
            )
            digest_doc = self.fake_db.collection("notification_queue").document("digest_recipient-1_20261122").get().to_dict()
            self.assertEqual(digest_doc["reactionsCount"], 1)

    def test_comment_immediate_then_30min_cooldown_grouped(self) -> None:
        t1 = datetime(2026, 11, 22, 11, 0, tzinfo=timezone.utc)  # 14:00 Istanbul
        t2 = t1 + timedelta(minutes=10)
        t3 = t1 + timedelta(minutes=20)
        flush_time = t1 + timedelta(minutes=31)

        with patch.object(notification_service, "get_firestore_client", return_value=self.fake_db):
            res1 = notification_service.record_social_event(
                "actor-1",
                SocialNotificationEventRequest(
                    event_type="comment",
                    post_id="post-1",
                    comment_id="c-1",
                    actor_name="Ada",
                    comment_preview="Harika yazı",
                ),
                now_utc=t1,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(res1["status"], "sent")
            self.assertEqual(len(self.sent_messages), 1)
            self.assertIn("Cinema", self.sent_messages[0].notification.body)
            self.assertIn("Harika yazı", self.sent_messages[0].notification.body)
            self.assertIsNone(self.sent_messages[0].apns.payload.aps.badge)

            # Second & third comments within 30 min cooldown get grouped in queue
            res2 = notification_service.record_social_event(
                "actor-2",
                SocialNotificationEventRequest(event_type="comment", post_id="post-1", comment_id="c-2", actor_name="Ece"),
                now_utc=t2,
                multicast_sender=self._fake_send,
            )
            res3 = notification_service.record_social_event(
                "actor-3",
                SocialNotificationEventRequest(event_type="comment", post_id="post-1", comment_id="c-3", actor_name="Can"),
                now_utc=t3,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(res2["status"], "queued")
            self.assertEqual(res3["status"], "queued")
            self.assertEqual(len(self.sent_messages), 1)

            flushed = notification_service.process_due_notifications(
                now_utc=flush_time,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(flushed["sent"], 1)
            self.assertEqual(len(self.sent_messages), 2)
            self.assertIn("Cinema", self.sent_messages[1].notification.body)
            self.assertIn("2 yeni yorum", self.sent_messages[1].notification.body)

    def test_comment_during_quiet_hours_defers_to_0830(self) -> None:
        quiet_utc = datetime(2026, 11, 22, 20, 30, tzinfo=timezone.utc)  # 23:30 Istanbul
        morning_utc = datetime(2026, 11, 23, 5, 31, tzinfo=timezone.utc)  # 08:31 Istanbul

        with patch.object(notification_service, "get_firestore_client", return_value=self.fake_db):
            res = notification_service.record_social_event(
                "actor-1",
                SocialNotificationEventRequest(event_type="comment", post_id="post-1", comment_id="c-1", actor_name="Ada"),
                now_utc=quiet_utc,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(res["status"], "queued")
            self.assertEqual(len(self.sent_messages), 0)

            early = notification_service.process_due_notifications(
                now_utc=datetime(2026, 11, 23, 4, 0, tzinfo=timezone.utc),
                multicast_sender=self._fake_send,
            )
            self.assertEqual(early["sent"], 0)

            morning = notification_service.process_due_notifications(
                now_utc=morning_utc,
                multicast_sender=self._fake_send,
            )
            self.assertEqual(morning["sent"], 1)
            self.assertEqual(len(self.sent_messages), 1)

    def test_follow_and_reaction_digest_aggregation_and_stale_token_prune(self) -> None:
        day_utc = datetime(2026, 11, 22, 11, 0, tzinfo=timezone.utc)  # 14:00 Istanbul
        evening_utc = datetime(2026, 11, 22, 16, 5, tzinfo=timezone.utc)  # 19:05 Istanbul
        self.fake_db.collection("users").document("recipient-1").collection("followers").document("actor-1").set(
            {"followerDisplayName": "Ada"}
        )
        self.fake_db.collection("users").document("recipient-1").collection("devices").document("stale-dev").set(
            {"fcmToken": "dead-token", "platform": "ios"}
        )

        def _send_with_prune(message: messaging.MulticastMessage):
            self.sent_messages.append(message)
            resps = []
            for tok in message.tokens:
                if tok == "dead-token":
                    resps.append(_FakeSendResp(False, messaging.UnregisteredError("not registered")))
                else:
                    resps.append(_FakeSendResp(True))
            return _FakeBatchResp(resps)

        with patch.object(notification_service, "get_firestore_client", return_value=self.fake_db):
            f_res = notification_service.record_social_event(
                "actor-1",
                SocialNotificationEventRequest(event_type="follow", target_uid="recipient-1"),
                now_utc=day_utc,
                multicast_sender=_send_with_prune,
            )
            r_res = notification_service.record_social_event(
                "actor-2",
                SocialNotificationEventRequest(event_type="reaction", post_id="post-1"),
                now_utc=day_utc + timedelta(minutes=5),
                multicast_sender=_send_with_prune,
            )
            self.assertEqual(f_res["status"], "queued")
            self.assertEqual(r_res["status"], "queued")
            self.assertEqual(len(self.sent_messages), 0)

            flushed = notification_service.process_due_notifications(
                now_utc=evening_utc,
                multicast_sender=_send_with_prune,
            )
            self.assertEqual(flushed["sent"], 1)
            self.assertEqual(len(self.sent_messages), 1)
            self.assertIn("1 yeni takipçin", self.sent_messages[0].notification.body)
            self.assertIn("1 tepki", self.sent_messages[0].notification.body)
            # Stale device should be pruned
            stale_doc = (
                self.fake_db.collection("users")
                .document("recipient-1")
                .collection("devices")
                .document("stale-dev")
                .get()
            )
            self.assertFalse(stale_doc.exists)

    def test_process_queue_endpoint_auth(self) -> None:
        with patch.object(notifications_router, "NOTIFICATION_CRON_SECRET", "cron-secret-123"), patch.object(
            notification_service, "get_firestore_client", return_value=self.fake_db
        ):
            bad = self.client.post("/notifications/process-queue")
            self.assertEqual(bad.status_code, 401)
            self.assertEqual(bad.json()["code"], "unauthorized")

            ok = self.client.post(
                "/notifications/process-queue",
                headers={"X-Omakase-Cron-Secret": "cron-secret-123"},
            )
            self.assertEqual(ok.status_code, 200)
            self.assertEqual(ok.json()["processed"], 0)

    def test_multilingual_normalization_prompts_and_notifications(self) -> None:
        from app.config import SUPPORTED_LANGUAGES, normalize_language
        from app.prompts import (
            _deep_dive_language_instruction,
            _expand_system_for_language,
            _feed_language_instruction,
            _suggest_system_for_language,
        )
        from app.schemas import DeepDiveRequest, ExpandCategoryRequest, FeedRequest, SuggestRequest

        for code in SUPPORTED_LANGUAGES:
            self.assertEqual(normalize_language(code), code)
            self.assertEqual(normalize_language(f"{code}-TEST"), code)
            self.assertEqual(FeedRequest(language=code).language, code)
            self.assertEqual(SuggestRequest(language=code).language, code)
            self.assertEqual(ExpandCategoryRequest(category="Film", language=code).language, code)
            self.assertEqual(
                DeepDiveRequest(original_title="T", original_text="Body", language=code).language,
                code,
            )
            self.assertTrue(_feed_language_instruction(code))
            self.assertTrue(_deep_dive_language_instruction(code))
            self.assertTrue(_suggest_system_for_language(code))
            self.assertTrue(_expand_system_for_language(code))

            title, body, _ = notification_service.build_comment_copy(code, ["Ada"], 2, None)
            self.assertTrue(title)
            self.assertIn("2", body)
            titled_1, titled_body_1, _ = notification_service.build_comment_copy(
                code, ["Ada"], 1, "Breathtaking angle", post_title="Ozu's Tatami Shot"
            )
            self.assertTrue(titled_1)
            self.assertIn("Ozu's Tatami Shot", titled_body_1)
            self.assertIn("Breathtaking angle", titled_body_1)
            titled_2, titled_body_2, _ = notification_service.build_comment_copy(
                code, ["Ada"], 2, None, post_title="Ozu's Tatami Shot"
            )
            self.assertTrue(titled_2)
            self.assertIn("Ozu's Tatami Shot", titled_body_2)
            self.assertIn("2", titled_body_2)
            d_title, d_body, _ = notification_service.build_digest_copy(code, 3, 2)
            self.assertTrue(d_title)
            self.assertIn("3", d_body)
            self.assertIn("2", d_body)

        self.assertEqual(normalize_language("pt-BR"), "en")
        self.assertEqual(normalize_language("de-DE"), "de")
        self.assertEqual(normalize_language("ja-JP"), "ja")


if __name__ == "__main__":
    unittest.main()
