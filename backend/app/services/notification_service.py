"""Social push notifications service (APNs/FCM via Firebase Admin Messaging).

Implements v1.0 notification rules:
- Comments: immediate push outside cooldown (30 min per user+post) and quiet hours (22:00-08:00 local).
  Multiple comments within the cooldown window or during quiet hours are grouped in `notification_queue`.
- Followers & Reactions: never sent immediately; aggregated per recipient day into a daily digest queue.
- Respects recipient preferences (`users/{uid}/notification_prefs/settings`) and bilateral block lists.
- Never sets APNs `badge` (HIG notifications Rule 8).
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from firebase_admin import messaging

from app.config import (
    COMMENT_COOLDOWN_MINUTES,
    DAILY_DIGEST_HOUR,
    QUIET_HOURS_DELIVER_HOUR,
    QUIET_HOURS_DELIVER_MINUTE,
    QUIET_HOURS_END,
    QUIET_HOURS_START,
    logger,
    normalize_language,
)
from app.errors import ErrorCode, OmakaseAPIError
from app.schemas import SocialNotificationEventRequest
from app.security import _BLOCKLIST_RE, _sanitize_single_line
from app.services.access_service import parse_iso_datetime
from app.services.firestore_admin import get_firestore_client

_DEFAULT_TZ = "Europe/Istanbul"
_DEFAULT_LANG = "tr"


def _resolve_zone(tz_name: Optional[str]) -> tuple[ZoneInfo, str]:
    if tz_name and isinstance(tz_name, str) and tz_name.strip():
        candidate = tz_name.strip()
        try:
            return ZoneInfo(candidate), candidate
        except ZoneInfoNotFoundError:
            pass
    try:
        return ZoneInfo(_DEFAULT_TZ), _DEFAULT_TZ
    except ZoneInfoNotFoundError:
        return ZoneInfo("UTC"), "UTC"


def _coerce_utc(value: Any) -> Optional[datetime]:
    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)
    if isinstance(value, str):
        return parse_iso_datetime(value)
    return None


def is_quiet_hours(now_local: datetime) -> bool:
    """Return True when recipient's local time falls in quiet hours (22:00-08:00)."""
    return now_local.hour >= QUIET_HOURS_START or now_local.hour < QUIET_HOURS_END


def next_quiet_hours_delivery_utc(now_utc: datetime, tz_name: Optional[str]) -> datetime:
    """Compute the next 08:30 local delivery timestamp (converted to UTC) outside quiet hours."""
    zone, _ = _resolve_zone(tz_name)
    local_now = now_utc.astimezone(zone)
    candidate = datetime(
        local_now.year,
        local_now.month,
        local_now.day,
        QUIET_HOURS_DELIVER_HOUR,
        QUIET_HOURS_DELIVER_MINUTE,
        tzinfo=zone,
    )
    if local_now.hour >= QUIET_HOURS_START or candidate <= local_now:
        candidate += timedelta(days=1)
    return candidate.astimezone(timezone.utc)


def next_digest_delivery_utc(now_utc: datetime, tz_name: Optional[str]) -> datetime:
    """Compute next daily digest delivery time in UTC, strictly avoiding 22:00-08:00 quiet hours."""
    zone, _ = _resolve_zone(tz_name)
    local_now = now_utc.astimezone(zone)
    if is_quiet_hours(local_now):
        return next_quiet_hours_delivery_utc(now_utc, tz_name)
    target = datetime(
        local_now.year,
        local_now.month,
        local_now.day,
        DAILY_DIGEST_HOUR,
        0,
        tzinfo=zone,
    )
    if local_now.hour >= DAILY_DIGEST_HOUR:
        target += timedelta(days=1)
    return target.astimezone(timezone.utc)


_COMMENT_COPY: dict[str, dict[str, str]] = {
    "en": {
        "single_title_actor": "{actor} commented",
        "single_title_anon": "New Comment",
        "single_body_empty": "Someone commented on your shared post.",
        "single_body_titled_empty": "Your plate “{post_title}” received a new comment.",
        "single_preview_titled": "“{post_title}”: {preview}",
        "multi_title": "New Comments",
        "multi_body": "Your shared post received {count} new comments.",
        "multi_body_titled": "Your plate “{post_title}” received {count} new comments.",
    },
    "tr": {
        "single_title_actor": "{actor} yorum yaptı",
        "single_title_anon": "Yeni yorum",
        "single_body_empty": "Paylaşımına yeni bir yorum geldi.",
        "single_body_titled_empty": "“{post_title}” paylaşımına yeni bir yorum geldi.",
        "single_preview_titled": "“{post_title}”: {preview}",
        "multi_title": "Gönderine yeni yorumlar",
        "multi_body": "Paylaşımına {count} yeni yorum geldi.",
        "multi_body_titled": "“{post_title}” paylaşımına {count} yeni yorum geldi.",
    },
    "ja": {
        "single_title_actor": "{actor}さんがコメントしました",
        "single_title_anon": "新しいコメント",
        "single_body_empty": "共有した投稿に新しいコメントが届きました。",
        "single_body_titled_empty": "「{post_title}」に新しいコメントが届きました。",
        "single_preview_titled": "「{post_title}」：{preview}",
        "multi_title": "新しいコメント",
        "multi_body": "共有した投稿に{count}件の新しいコメントが届きました。",
        "multi_body_titled": "「{post_title}」に{count}件の新しいコメントが届きました。",
    },
    "de": {
        "single_title_actor": "{actor} hat kommentiert",
        "single_title_anon": "Neuer Kommentar",
        "single_body_empty": "Jemand hat deinen geteilten Beitrag kommentiert.",
        "single_body_titled_empty": "Zu „{post_title}“ gibt es einen neuen Kommentar.",
        "single_preview_titled": "„{post_title}“: {preview}",
        "multi_title": "Neue Kommentare",
        "multi_body": "Dein geteilter Beitrag hat {count} neue Kommentare erhalten.",
        "multi_body_titled": "Dein Beitrag „{post_title}“ hat {count} neue Kommentare erhalten.",
    },
    "fr": {
        "single_title_actor": "{actor} a commenté",
        "single_title_anon": "Nouveau commentaire",
        "single_body_empty": "Quelqu'un a commenté votre publication partagée.",
        "single_body_titled_empty": "Nouveau commentaire sur « {post_title} ».",
        "single_preview_titled": "« {post_title} » : {preview}",
        "multi_title": "Nouveaux commentaires",
        "multi_body": "Votre publication a reçu {count} nouveaux commentaires.",
        "multi_body_titled": "« {post_title} » a reçu {count} nouveaux commentaires.",
    },
    "es": {
        "single_title_actor": "{actor} comentó",
        "single_title_anon": "Nuevo comentario",
        "single_body_empty": "Alguien comentó tu publicación compartida.",
        "single_body_titled_empty": "Nuevo comentario en «{post_title}».",
        "single_preview_titled": "«{post_title}»: {preview}",
        "multi_title": "Nuevos comentarios",
        "multi_body": "Tu publicación recibió {count} comentarios nuevos.",
        "multi_body_titled": "«{post_title}» recibió {count} comentarios nuevos.",
    },
    "ko": {
        "single_title_actor": "{actor}님이 댓글을 남겼습니다",
        "single_title_anon": "새 댓글",
        "single_body_empty": "공유한 게시물에 새 댓글이 달렸습니다.",
        "single_body_titled_empty": "“{post_title}” 게시물에 새 댓글이 달렸습니다.",
        "single_preview_titled": "“{post_title}”: {preview}",
        "multi_title": "새 댓글",
        "multi_body": "공유한 게시물에 새 댓글 {count}개가 달렸습니다.",
        "multi_body_titled": "“{post_title}”에 새 댓글 {count}개가 달렸습니다.",
    },
}

_DIGEST_COPY: dict[str, dict[str, str]] = {
    "en": {
        "both_title": "Omakase Community",
        "both_body": "You gained {followers} new {f_noun} and {reactions} {r_noun} today.",
        "follow_title": "New Followers",
        "follow_one": "1 new person followed you today.",
        "follow_many": "{followers} new people followed you today.",
        "react_title": "New Reactions",
        "react_one": "Your shared post received 1 reaction today.",
        "react_many": "Your shared post received {reactions} reactions today.",
    },
    "tr": {
        "both_title": "Omakase Topluluk",
        "both_body": "Bugün {followers} yeni takipçin ve paylaşımlarına {reactions} tepki var.",
        "follow_title": "Yeni takipçiler",
        "follow_one": "Bugün {followers} yeni kişi seni takip etmeye başladı.",
        "follow_many": "Bugün {followers} yeni kişi seni takip etmeye başladı.",
        "react_title": "Paylaşımına tepkiler",
        "react_one": "Paylaşımın bugün {reactions} tepki aldı.",
        "react_many": "Paylaşımın bugün {reactions} tepki aldı.",
    },
    "ja": {
        "both_title": "Omakase コミュニティ",
        "both_body": "今日は新しいフォロワーが{followers}人、リアクションが{reactions}件ありました。",
        "follow_title": "新しいフォロワー",
        "follow_one": "今日、新しいフォロワーが1人増えました。",
        "follow_many": "今日、新しいフォロワーが{followers}人増えました。",
        "react_title": "新しいリアクション",
        "react_one": "共有した投稿に今日1件のリアクションがありました。",
        "react_many": "共有した投稿に今日{reactions}件のリアクションがありました。",
    },
    "de": {
        "both_title": "Omakase Community",
        "both_body": "Heute hast du {followers} neue Follower und {reactions} Reaktionen erhalten.",
        "follow_title": "Neue Follower",
        "follow_one": "Heute folgt dir 1 neue Person.",
        "follow_many": "Heute folgen dir {followers} neue Personen.",
        "react_title": "Neue Reaktionen",
        "react_one": "Dein geteilter Beitrag erhielt heute 1 Reaktion.",
        "react_many": "Dein geteilter Beitrag erhielt heute {reactions} Reaktionen.",
    },
    "fr": {
        "both_title": "Omakase Communauté",
        "both_body": "Aujourd'hui : {followers} nouvel(s) abonné(s) et {reactions} réaction(s).",
        "follow_title": "Nouveaux abonnés",
        "follow_one": "1 nouvelle personne vous suit aujourd'hui.",
        "follow_many": "{followers} nouvelles personnes vous suivent aujourd'hui.",
        "react_title": "Nouvelles réactions",
        "react_one": "Votre publication a reçu 1 réaction aujourd'hui.",
        "react_many": "Votre publication a reçu {reactions} réactions aujourd'hui.",
    },
    "es": {
        "both_title": "Comunidad Omakase",
        "both_body": "Hoy conseguiste {followers} seguidores nuevos y {reactions} reacciones.",
        "follow_title": "Nuevos seguidores",
        "follow_one": "Hoy empezó a seguirte 1 persona nueva.",
        "follow_many": "Hoy empezaron a seguirte {followers} personas nuevas.",
        "react_title": "Nuevas reacciones",
        "react_one": "Tu publicación recibió 1 reacción hoy.",
        "react_many": "Tu publicación recibió {reactions} reacciones hoy.",
    },
    "ko": {
        "both_title": "Omakase 커뮤니티",
        "both_body": "오늘 새 팔로워 {followers}명과 반응 {reactions}개를 받았습니다.",
        "follow_title": "새 팔로워",
        "follow_one": "오늘 새로운 팔로워 1명이 생겼습니다.",
        "follow_many": "오늘 새로운 팔로워 {followers}명이 생겼습니다.",
        "react_title": "새 반응",
        "react_one": "오늘 공유한 게시물이 반응 1개를 받았습니다.",
        "react_many": "오늘 공유한 게시물이 반응 {reactions}개를 받았습니다.",
    },
}


def _truncate_post_title(post_title: Optional[str], limit: int = 60) -> str:
    collapsed = " ".join((post_title or "").split()).strip("\"'“”«»「」")
    if not collapsed:
        return ""
    if len(collapsed) <= limit:
        return collapsed
    cut = collapsed[: limit - 1]
    if " " in cut and cut.rfind(" ") > limit // 2:
        cut = cut[: cut.rfind(" ")]
    return f"{cut.rstrip()}…"


def build_comment_copy(
    language: str,
    actor_names: list[str],
    count: int,
    preview: Optional[str],
    post_title: Optional[str] = None,
) -> tuple[str, str, str]:
    """Return `(title, body, apns_category_id)` for immediate or grouped comment notifications."""
    lang = normalize_language(language)
    copy = _COMMENT_COPY[lang]
    category = "COMMENT_NOTIFICATION"
    clean_preview = (preview or "").strip()
    clean_post_title = _truncate_post_title(post_title)

    if count <= 1:
        raw_actor = next((n.strip() for n in actor_names if n and n.strip()), "")
        display_actor = (
            raw_actor
            if (not raw_actor or " " in raw_actor or raw_actor.startswith("@"))
            else f"@{raw_actor}"
        )
        title = (
            copy["single_title_actor"].format(actor=display_actor)
            if display_actor
            else copy["single_title_anon"]
        )
        if clean_post_title:
            body = (
                copy["single_preview_titled"].format(post_title=clean_post_title, preview=clean_preview)
                if clean_preview
                else copy["single_body_titled_empty"].format(post_title=clean_post_title)
            )
        else:
            body = clean_preview if clean_preview else copy["single_body_empty"]
        return title, body, category

    if clean_post_title:
        return (
            copy["multi_title"],
            copy["multi_body_titled"].format(post_title=clean_post_title, count=count),
            category,
        )

    return (
        copy["multi_title"],
        copy["multi_body"].format(count=count),
        category,
    )


def build_digest_copy(
    language: str,
    followers_count: int,
    reactions_count: int,
) -> tuple[str, str, str]:
    """Return `(title, body, apns_category_id)` for daily follower + reaction digest notifications."""
    lang = normalize_language(language)
    copy = _DIGEST_COPY[lang]
    category = "SOCIAL_DIGEST"

    if followers_count > 0 and reactions_count > 0:
        f_noun = "follower" if followers_count == 1 else "followers"
        r_noun = "reaction" if reactions_count == 1 else "reactions"
        return (
            copy["both_title"],
            copy["both_body"].format(
                followers=followers_count,
                reactions=reactions_count,
                f_noun=f_noun,
                r_noun=r_noun,
            ),
            category,
        )

    if followers_count > 0:
        body = (
            copy["follow_one"].format(followers=followers_count)
            if followers_count == 1
            else copy["follow_many"].format(followers=followers_count)
        )
        return copy["follow_title"], body, category

    body = (
        copy["react_one"].format(reactions=reactions_count)
        if reactions_count == 1
        else copy["react_many"].format(reactions=reactions_count)
    )
    return copy["react_title"], body, category


def _is_unregistered_fcm_error(exc: Optional[BaseException]) -> bool:
    if exc is None:
        return False
    if isinstance(exc, messaging.UnregisteredError):
        return True
    code = str(getattr(exc, "code", "")).lower()
    msg = str(exc).lower()
    return (
        "unregistered" in code
        or "registration-token-not-registered" in code
        or "requested entity was not found" in msg
    )


def _read_recipient_prefs(db: Any, uid: str) -> dict[str, Any]:
    defaults = {
        "commentPushEnabled": True,
        "dailyDigestEnabled": True,
        "timezone": _DEFAULT_TZ,
        "language": _DEFAULT_LANG,
    }
    try:
        snap = (
            db.collection("users")
            .document(uid)
            .collection("notification_prefs")
            .document("settings")
            .get()
        )
        if snap.exists:
            data = snap.to_dict() or {}
            defaults["commentPushEnabled"] = bool(data.get("commentPushEnabled", True))
            defaults["dailyDigestEnabled"] = bool(data.get("dailyDigestEnabled", True))
            defaults["timezone"] = str(data.get("timezone") or _DEFAULT_TZ)
            defaults["language"] = str(data.get("language") or _DEFAULT_LANG)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed reading notification_prefs for uid=%s: %s", uid, exc)
    return defaults


def _is_blocked_pair(db: Any, uid_a: str, uid_b: str) -> bool:
    try:
        a_blocks_b = (
            db.collection("users")
            .document(uid_a)
            .collection("blocked_users")
            .document(uid_b)
            .get()
        )
        if a_blocks_b.exists:
            return True
        b_blocks_a = (
            db.collection("users")
            .document(uid_b)
            .collection("blocked_users")
            .document(uid_a)
            .get()
        )
        return bool(b_blocks_a.exists)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed block check between %s and %s: %s", uid_a, uid_b, exc)
        return False


def _resolve_recipient_and_post_title(
    db: Any,
    actor_uid: str,
    req: SocialNotificationEventRequest,
) -> tuple[Optional[str], str, Optional[str]]:
    if req.event_type in ("comment", "reaction"):
        if not req.post_id:
            raise OmakaseAPIError(
                status_code=422,
                code=ErrorCode.INVALID_REQUEST,
                detail="post_id is required for comment/reaction notifications.",
            )
        post_snap = db.collection("shared_posts").document(req.post_id).get()
        if not post_snap.exists:
            return None, "", None
        post_data = post_snap.to_dict() or {}
        author_id = str(post_data.get("authorId") or "").strip()
        post_title = str(post_data.get("title") or "").strip()

        if req.event_type == "comment":
            if not req.comment_id:
                raise OmakaseAPIError(
                    status_code=422,
                    code=ErrorCode.INVALID_REQUEST,
                    detail="comment_id is required for comment notifications.",
                )
            comment_snap = (
                db.collection("shared_posts")
                .document(req.post_id)
                .collection("comments")
                .document(req.comment_id)
                .get()
            )
            if not comment_snap.exists:
                return None, "", None
            comment_data = comment_snap.to_dict() or {}
            if str(comment_data.get("authorId") or "").strip() != actor_uid:
                return None, "", None
            verified_preview = _sanitize_single_line(
                str(comment_data.get("text") or ""), 160
            )
            if not verified_preview or _BLOCKLIST_RE.search(verified_preview):
                verified_preview = None
            return (author_id or None), post_title, verified_preview

        # Reaction: verify caller has an active reaction document on the target post (S-17).
        reaction_snap = (
            db.collection("shared_posts")
            .document(req.post_id)
            .collection("reactions")
            .document(actor_uid)
            .get()
        )
        if not reaction_snap.exists:
            return None, "", None
        return (author_id or None), post_title, None

    if not req.target_uid:
        raise OmakaseAPIError(
            status_code=422,
            code=ErrorCode.INVALID_REQUEST,
            detail="target_uid is required for follow notifications.",
        )
    # Confirm the follower relationship exists so arbitrary users cannot spam unrelated targets.
    follower_snap = (
        db.collection("users")
        .document(req.target_uid)
        .collection("followers")
        .document(actor_uid)
        .get()
    )
    if not follower_snap.exists:
        return None, "", None
    return req.target_uid, "", None


def _resolve_recipient_uid(
    db: Any,
    actor_uid: str,
    req: SocialNotificationEventRequest,
) -> Optional[str]:
    recipient_uid, _, _ = _resolve_recipient_and_post_title(db, actor_uid, req)
    return recipient_uid


def _resolve_actor_display_name(
    db: Any,
    actor_uid: str,
    fallback_name: Optional[str] = None,
) -> Optional[str]:
    """Resolve authoritative actor display name from Firestore to prevent push spoofing (S-17)."""
    _ = fallback_name
    try:
        user_snap = db.collection("users").document(actor_uid).get()
        if user_snap.exists:
            data = user_snap.to_dict() or {}
            username = str(data.get("username") or "").strip()
            display_name = str(data.get("displayName") or "").strip()
            if username:
                return username
            if display_name:
                return display_name
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed reading actor profile for uid=%s: %s", actor_uid, exc)
    return None


def send_fcm_to_user(
    db: Any,
    uid: str,
    title: str,
    body: str,
    category_id: str,
    data: dict[str, str],
    thread_id: Optional[str] = None,
    multicast_sender: Optional[Callable[[messaging.MulticastMessage], Any]] = None,
) -> dict[str, Any]:
    """Send a push notification to all registered iOS devices of `uid` and prune stale tokens."""
    device_docs = list(db.collection("users").document(uid).collection("devices").stream())
    token_pairs: list[tuple[str, str]] = []
    for doc in device_docs:
        d = doc.to_dict() or {}
        token = str(d.get("fcmToken") or "").strip()
        if token:
            token_pairs.append((doc.id, token))

    if not token_pairs:
        return {"sent": 0, "failed": 0, "pruned": 0}

    tokens = [pair[1] for pair in token_pairs]
    # Intentionally omit `badge` from APNs payload per HIG notifications Rule 8 & v1.0 spec.
    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in data.items()},
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound="default",
                    category=category_id,
                    thread_id=thread_id,
                )
            )
        ),
    )

    sender = multicast_sender or messaging.send_each_for_multicast
    batch_response = sender(message)

    sent = 0
    failed = 0
    pruned = 0
    responses = getattr(batch_response, "responses", [])
    for idx, resp in enumerate(responses):
        if getattr(resp, "success", False):
            sent += 1
        else:
            failed += 1
            exc = getattr(resp, "exception", None)
            if _is_unregistered_fcm_error(exc) and idx < len(token_pairs):
                device_id = token_pairs[idx][0]
                try:
                    db.collection("users").document(uid).collection("devices").document(device_id).delete()
                    pruned += 1
                except Exception as del_exc:  # noqa: BLE001
                    logger.warning("Failed pruning stale device %s for uid=%s: %s", device_id, uid, del_exc)

    return {"sent": sent, "failed": failed, "pruned": pruned}


def record_social_event(
    actor_uid: str,
    req: SocialNotificationEventRequest,
    now_utc: Optional[datetime] = None,
    multicast_sender: Optional[Callable[[messaging.MulticastMessage], Any]] = None,
) -> dict[str, Any]:
    """Process an incoming comment, follow, or reaction notification event."""
    db = get_firestore_client()
    if db is None:
        return {"status": "ignored", "reason": "firestore_unavailable"}

    now = (now_utc or datetime.now(timezone.utc)).astimezone(timezone.utc)
    recipient_uid, post_title, verified_comment_preview = _resolve_recipient_and_post_title(
        db, actor_uid, req
    )
    if not recipient_uid:
        return {"status": "ignored", "reason": "target_not_found"}
    if recipient_uid == actor_uid:
        return {"status": "ignored", "reason": "self"}
    if _is_blocked_pair(db, recipient_uid, actor_uid):
        return {"status": "ignored", "reason": "blocked"}

    prefs = _read_recipient_prefs(db, recipient_uid)
    tz_name = prefs["timezone"]
    language = prefs["language"]
    zone, resolved_tz = _resolve_zone(tz_name)
    local_now = now.astimezone(zone)

    if req.event_type == "comment":
        if not prefs["commentPushEnabled"]:
            return {"status": "ignored", "reason": "disabled"}

        resolved_actor_name = _resolve_actor_display_name(db, actor_uid)
        assert req.post_id is not None
        cooldown_id = f"{recipient_uid}_{req.post_id}"
        cooldown_ref = db.collection("notification_cooldowns").document(cooldown_id)
        cooldown_snap = cooldown_ref.get()
        last_sent_at = (
            _coerce_utc((cooldown_snap.to_dict() or {}).get("lastSentAt"))
            if cooldown_snap.exists
            else None
        )
        cooldown_until = (
            last_sent_at + timedelta(minutes=COMMENT_COOLDOWN_MINUTES)
            if last_sent_at is not None
            else None
        )
        in_cooldown = cooldown_until is not None and now < cooldown_until
        in_quiet = is_quiet_hours(local_now)

        if not in_cooldown and not in_quiet:
            actors = [resolved_actor_name] if resolved_actor_name else []
            title, body, category = build_comment_copy(
                language,
                actors,
                1,
                verified_comment_preview,
                post_title=post_title,
            )
            delivery = send_fcm_to_user(
                db=db,
                uid=recipient_uid,
                title=title,
                body=body,
                category_id=category,
                data={"route": "post", "postId": req.post_id},
                thread_id=f"post_{req.post_id}",
                multicast_sender=multicast_sender,
            )
            cooldown_ref.set(
                {
                    "recipientUid": recipient_uid,
                    "postId": req.post_id,
                    "lastSentAt": now,
                },
                merge=True,
            )
            return {"status": "sent", **delivery}

        deliver_at = now
        if in_cooldown and cooldown_until is not None:
            deliver_at = cooldown_until
        if is_quiet_hours(deliver_at.astimezone(zone)):
            deliver_at = next_quiet_hours_delivery_utc(deliver_at, resolved_tz)

        queue_id = f"comment_{recipient_uid}_{req.post_id}"
        queue_ref = db.collection("notification_queue").document(queue_id)
        existing_snap = queue_ref.get()
        existing = (existing_snap.to_dict() or {}) if existing_snap.exists else {}
        if existing.get("status") != "pending":
            existing = {}

        actor_names: list[str] = list(existing.get("actorNames") or [])
        if resolved_actor_name and resolved_actor_name not in actor_names and len(actor_names) < 5:
            actor_names.append(resolved_actor_name)
        count = int(existing.get("count") or 0) + 1
        queue_ref.set(
            {
                "status": "pending",
                "kind": "comment",
                "recipientUid": recipient_uid,
                "postId": req.post_id,
                "postTitle": post_title or existing.get("postTitle") or "",
                "count": count,
                "actorNames": actor_names,
                "lastPreview": verified_comment_preview or existing.get("lastPreview") or "",
                "deliverAt": deliver_at,
                "updatedAt": now,
            },
            merge=True,
        )
        return {"status": "queued", "queueId": queue_id, "deliverAt": deliver_at.isoformat()}

    # Follow & reaction are aggregated into the daily digest queue.
    if not prefs["dailyDigestEnabled"]:
        return {"status": "ignored", "reason": "disabled"}

    day_key = local_now.strftime("%Y%m%d")
    queue_id = f"digest_{recipient_uid}_{day_key}"
    queue_ref = db.collection("notification_queue").document(queue_id)
    existing_snap = queue_ref.get()
    existing = (existing_snap.to_dict() or {}) if existing_snap.exists else {}
    if existing.get("status") != "pending":
        existing = {}

    follower_uids: list[str] = list(existing.get("followerUids") or [])
    reactor_uids: list[str] = list(existing.get("reactorUids") or [])
    followers_count = int(existing.get("followersCount") or 0)
    reactions_count = int(existing.get("reactionsCount") or 0)

    if req.event_type == "follow":
        if actor_uid not in follower_uids:
            follower_uids.append(actor_uid)
            followers_count = max(followers_count + 1, len(follower_uids))
    else:
        reactor_key = f"{actor_uid}:{req.post_id or ''}"
        if reactor_key not in reactor_uids:
            reactor_uids.append(reactor_key)
            reactions_count = max(reactions_count + 1, len(reactor_uids))

    existing_deliver = _coerce_utc(existing.get("deliverAt"))
    deliver_at = existing_deliver if existing_deliver else next_digest_delivery_utc(now, resolved_tz)
    queue_ref.set(
        {
            "status": "pending",
            "kind": "digest",
            "recipientUid": recipient_uid,
            "dayKey": day_key,
            "followerUids": follower_uids[:100],
            "reactorUids": reactor_uids[:100],
            "followersCount": followers_count,
            "reactionsCount": reactions_count,
            "deliverAt": deliver_at,
            "updatedAt": now,
        },
        merge=True,
    )
    return {"status": "queued", "queueId": queue_id, "deliverAt": deliver_at.isoformat()}


def process_due_notifications(
    now_utc: Optional[datetime] = None,
    limit: int = 200,
    multicast_sender: Optional[Callable[[messaging.MulticastMessage], Any]] = None,
) -> dict[str, Any]:
    """Flush due pending items in `notification_queue`, respecting quiet hours and user prefs."""
    db = get_firestore_client()
    if db is None:
        return {"processed": 0, "sent": 0, "deferred": 0, "skipped": 0}

    now = (now_utc or datetime.now(timezone.utc)).astimezone(timezone.utc)
    # Single-field inequality query uses Firestore's built-in automatic index on `deliverAt`
    # without requiring a custom composite index; completed items clear `deliverAt = None`.
    docs = list(
        db.collection("notification_queue")
        .where("deliverAt", "<=", now)
        .limit(limit)
        .stream()
    )

    processed = 0
    sent_count = 0
    deferred = 0
    skipped = 0

    for doc in docs:
        item = doc.to_dict() or {}
        if item.get("status") != "pending":
            continue
        processed += 1
        recipient_uid = str(item.get("recipientUid") or "").strip()
        kind = str(item.get("kind") or "").strip()
        if not recipient_uid or kind not in ("comment", "digest"):
            doc.reference.set({"status": "skipped", "deliverAt": None, "updatedAt": now}, merge=True)
            skipped += 1
            continue

        prefs = _read_recipient_prefs(db, recipient_uid)
        tz_name = prefs["timezone"]
        language = prefs["language"]
        zone, resolved_tz = _resolve_zone(tz_name)
        local_now = now.astimezone(zone)

        if (kind == "comment" and not prefs["commentPushEnabled"]) or (
            kind == "digest" and not prefs["dailyDigestEnabled"]
        ):
            doc.reference.set({"status": "skipped", "deliverAt": None, "updatedAt": now}, merge=True)
            skipped += 1
            continue

        if is_quiet_hours(local_now):
            new_deliver = next_quiet_hours_delivery_utc(now, resolved_tz)
            doc.reference.set({"deliverAt": new_deliver, "updatedAt": now}, merge=True)
            deferred += 1
            continue

        if kind == "comment":
            post_id = str(item.get("postId") or "")
            post_title = str(item.get("postTitle") or "")
            count = int(item.get("count") or 1)
            actors = list(item.get("actorNames") or [])
            preview = item.get("lastPreview")
            title, body, category = build_comment_copy(
                language,
                actors,
                count,
                preview,
                post_title=post_title,
            )
            send_fcm_to_user(
                db=db,
                uid=recipient_uid,
                title=title,
                body=body,
                category_id=category,
                data={"route": "post", "postId": post_id},
                thread_id=f"post_{post_id}",
                multicast_sender=multicast_sender,
            )
            if post_id:
                db.collection("notification_cooldowns").document(f"{recipient_uid}_{post_id}").set(
                    {"recipientUid": recipient_uid, "postId": post_id, "lastSentAt": now},
                    merge=True,
                )
        else:
            followers_count = int(item.get("followersCount") or 0)
            reactions_count = int(item.get("reactionsCount") or 0)
            if followers_count == 0 and reactions_count == 0:
                doc.reference.set({"status": "skipped", "deliverAt": None, "updatedAt": now}, merge=True)
                skipped += 1
                continue
            title, body, category = build_digest_copy(language, followers_count, reactions_count)
            send_fcm_to_user(
                db=db,
                uid=recipient_uid,
                title=title,
                body=body,
                category_id=category,
                data={"route": "community"},
                thread_id=f"digest_{recipient_uid}",
                multicast_sender=multicast_sender,
            )

        doc.reference.set(
            {"status": "sent", "sentAt": now, "deliverAt": None, "updatedAt": now},
            merge=True,
        )
        sent_count += 1

    return {"processed": processed, "sent": sent_count, "deferred": deferred, "skipped": skipped}


async def record_social_event_async(
    actor_uid: str,
    req: SocialNotificationEventRequest,
) -> dict[str, Any]:
    return await asyncio.to_thread(record_social_event, actor_uid, req)


async def process_due_notifications_async(limit: int = 200) -> dict[str, Any]:
    return await asyncio.to_thread(process_due_notifications, None, limit)
