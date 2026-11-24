"""Pydantic request models and input validators for all Omakase endpoints."""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field, field_validator

from app.config import normalize_language
from app.security import (
    _BLOCKLIST_RE,
    _LETTERBOXD_USERNAME_RE,
    _MAX_INTEREST_LEN,
    _sanitize_single_line,
    _validate_interests,
    _validate_letterboxd_films,
)


class FeedRequest(BaseModel):
    """Payload sent by the iOS client to request a single generated post."""

    interests: list[str] = Field(
        default_factory=list,
        description="Free-form user interests, e.g. ['David Fincher', 'Aftersun', 'Secret Hitler'].",
    )
    seen_count: int = Field(
        default=0,
        ge=0,
        le=100_000,
        description="Number of posts already shown; used to nudge the model toward variety.",
    )
    language: str = Field(
        default="en",
        description="BCP-47 language tag for model output (en, tr, ja, de, fr, es, ko). Unknown values fall back to English.",
    )
    letterboxd_films: Optional[list[dict]] = Field(
        default=None,
        description=(
            "Optional list of recently watched films from Letterboxd. "
            "Each dict has keys: title, year, rating (0-5), watched_date."
        ),
    )
    timezone: Optional[str] = Field(
        default=None,
        max_length=64,
        description="Caller's IANA timezone (e.g. Europe/Istanbul) for daily quota resets.",
    )

    @field_validator("language")
    @classmethod
    def _normalize_language(cls, v: str) -> str:
        return normalize_language(v)

    @field_validator("interests")
    @classmethod
    def _check_interests(cls, v: list[str]) -> list[str]:
        return _validate_interests(v)

    @field_validator("letterboxd_films")
    @classmethod
    def _check_letterboxd_films(cls, v: Optional[list[dict]]) -> Optional[list[dict]]:
        return _validate_letterboxd_films(v)


class SuggestRequest(BaseModel):
    """Payload for the interest-suggestion endpoint."""

    interests: list[str] = Field(
        default_factory=list,
        description="Interests the user has already added or is currently typing.",
    )
    draft: str = Field(
        default="",
        description="Partial text the user is typing right now (may be empty).",
    )
    exclude_suggestions: list[str] = Field(
        default_factory=list,
        description="Suggestions already shown; the model must not repeat these.",
    )
    language: str = Field(
        default="en",
        description="BCP-47 language tag for suggestion strings (en, tr, ja, de, fr, es, ko).",
    )
    timezone: Optional[str] = Field(default=None, max_length=64)

    @field_validator("language")
    @classmethod
    def _normalize_language_suggest(cls, v: str) -> str:
        return normalize_language(v)

    @field_validator("interests")
    @classmethod
    def _check_interests_suggest(cls, v: list[str]) -> list[str]:
        return _validate_interests(v)

    @field_validator("exclude_suggestions")
    @classmethod
    def _check_excluded_suggest(cls, v: list[str]) -> list[str]:
        cleaned: list[str] = []
        for raw in v[:100]:
            item = _sanitize_single_line(raw, _MAX_INTEREST_LEN)
            if item:
                cleaned.append(item)
        return cleaned

    @field_validator("draft")
    @classmethod
    def _check_draft(cls, v: str) -> str:
        v = _sanitize_single_line(v, 200)
        if _BLOCKLIST_RE.search(v):
            raise ValueError("Draft contains inappropriate content.")
        return v


class ExpandCategoryRequest(BaseModel):
    """Payload for the category-expansion endpoint."""

    category: str = Field(
        ...,
        description="Category name to expand (e.g. 'Film', 'Music').",
    )
    existing_interests: list[str] = Field(
        default_factory=list,
        description="Interests the user already has — so we don't repeat them.",
    )
    language: str = Field(
        default="en",
        description="BCP-47 language tag for suggestion strings (en, tr, ja, de, fr, es, ko).",
    )
    timezone: Optional[str] = Field(default=None, max_length=64)

    @field_validator("language")
    @classmethod
    def _normalize_language_expand(cls, v: str) -> str:
        return normalize_language(v)

    @field_validator("category")
    @classmethod
    def _check_category(cls, v: str) -> str:
        v = _sanitize_single_line(v, 100)
        if not v:
            raise ValueError("Category must not be empty.")
        if _BLOCKLIST_RE.search(v):
            raise ValueError("Category contains inappropriate content.")
        return v

    @field_validator("existing_interests")
    @classmethod
    def _check_existing_interests(cls, v: list[str]) -> list[str]:
        cleaned: list[str] = []
        for raw in v[:100]:
            item = _sanitize_single_line(raw, _MAX_INTEREST_LEN)
            if item and not _BLOCKLIST_RE.search(item):
                cleaned.append(item)
        return cleaned


class DeepDiveRequest(BaseModel):
    """Payload sent by the iOS client to request a deep-dive expansion of a post."""

    original_title: str = Field(..., min_length=1, max_length=300)
    original_text: str = Field(..., min_length=1, max_length=5000)
    interests: list[str] = Field(default_factory=list, max_length=30)
    language: str = "en"
    timezone: Optional[str] = Field(default=None, max_length=64)

    @field_validator("original_title")
    @classmethod
    def _check_title(cls, v: str) -> str:
        cleaned = _sanitize_single_line(v, 300)
        if not cleaned:
            raise ValueError("original_title must not be empty.")
        if _BLOCKLIST_RE.search(cleaned):
            raise ValueError("Title contains inappropriate content.")
        return cleaned

    @field_validator("original_text")
    @classmethod
    def _check_text(cls, v: str) -> str:
        cleaned = (v or "").replace("\x00", "").strip()[:5000]
        if not cleaned:
            raise ValueError("original_text must not be empty.")
        if _BLOCKLIST_RE.search(cleaned):
            raise ValueError("Text contains inappropriate content.")
        return cleaned

    @field_validator("interests")
    @classmethod
    def _check_deep_dive_interests(cls, v: list[str]) -> list[str]:
        return _validate_interests(v)

    @field_validator("language")
    @classmethod
    def _check_lang(cls, v: str) -> str:
        return normalize_language(v)


class LetterboxdFilmsRequest(BaseModel):
    """Payload for fetching a user's recent films from Letterboxd."""

    username: str = Field(..., min_length=1, max_length=40)
    limit: int = Field(default=50, ge=1, le=50)

    @field_validator("username")
    @classmethod
    def _validate_username(cls, v: str) -> str:
        cleaned = (v or "").strip().lstrip("@")
        if not _LETTERBOXD_USERNAME_RE.match(cleaned):
            raise ValueError(
                "Invalid Letterboxd username. Only letters, numbers, underscores, and hyphens (max 40 chars) are allowed."
            )
        return cleaned


class BillingSyncRequest(BaseModel):
    """Payload for POST /billing/sync."""

    timezone: Optional[str] = Field(default=None, max_length=64)


class RewardShareRequest(BaseModel):
    """Payload for POST /feed/reward-share."""

    timezone: Optional[str] = Field(default=None, max_length=64)


class SocialNotificationEventRequest(BaseModel):
    """Payload for POST /notifications/events to dispatch or enqueue a social push."""

    event_type: str = Field(..., description="One of: comment, follow, reaction.")
    target_uid: Optional[str] = Field(default=None, max_length=128)
    post_id: Optional[str] = Field(default=None, max_length=128)
    actor_name: Optional[str] = Field(default=None, max_length=100)
    comment_preview: Optional[str] = Field(default=None, max_length=160)

    @field_validator("event_type")
    @classmethod
    def _validate_event_type(cls, v: str) -> str:
        cleaned = (v or "").strip().lower()
        if cleaned not in ("comment", "follow", "reaction"):
            raise ValueError("Unsupported notification event_type.")
        return cleaned

    @field_validator("target_uid", "post_id")
    @classmethod
    def _clean_identifier(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = _sanitize_single_line(v, 128)
        return cleaned or None

    @field_validator("actor_name")
    @classmethod
    def _clean_actor_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = _sanitize_single_line(v, 100)
        return cleaned or None

    @field_validator("comment_preview")
    @classmethod
    def _clean_comment_preview(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = _sanitize_single_line(v, 160)
        if cleaned and _BLOCKLIST_RE.search(cleaned):
            return ""
        return cleaned or None
