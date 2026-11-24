"""Application configuration, environment settings, and Gemini SDK client initialization."""

from __future__ import annotations

import logging
import os
from typing import Optional

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger("omakase")

GEMINI_API_KEY: Optional[str] = os.getenv("GEMINI_API_KEY")

# gemini-3.5-flash is used for feed posts & deep dives for low-latency token streaming.
GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-3.5-flash")
GEMINI_DEEP_DIVE_MODEL: str = os.getenv("GEMINI_DEEP_DIVE_MODEL", "gemini-3.5-flash")
GEMINI_SUGGEST_MODEL: str = os.getenv("GEMINI_SUGGEST_MODEL", "gemini-3.1-flash-lite")

FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "gen-lang-client-0120875563")
REQUIRE_AUTH: bool = os.getenv("OMAKASE_REQUIRE_AUTH", "true").strip().lower() not in (
    "0",
    "false",
    "no",
)

REVENUECAT_SECRET_API_KEY: Optional[str] = os.getenv("REVENUECAT_SECRET_API_KEY")
REVENUECAT_WEBHOOK_SECRET: Optional[str] = os.getenv("REVENUECAT_WEBHOOK_SECRET")
REVENUECAT_ENTITLEMENT_ID: str = os.getenv("REVENUECAT_ENTITLEMENT_ID", "pro")
NOTIFICATION_CRON_SECRET: Optional[str] = os.getenv("NOTIFICATION_CRON_SECRET")

SUPPORTED_LANGUAGES: tuple[str, ...] = ("en", "tr", "ja", "de", "fr", "es", "ko")


def normalize_language(value: Optional[str]) -> str:
    """Normalize a BCP-47 language tag to one of `SUPPORTED_LANGUAGES`, defaulting to `'en'`."""
    raw = (value or "").strip().lower().replace("_", "-")
    if not raw:
        return "en"
    base = raw.split("-", 1)[0]
    return base if base in SUPPORTED_LANGUAGES else "en"

# Push notification policy constants (v1.0 social notifications)
COMMENT_COOLDOWN_MINUTES: int = 30
QUIET_HOURS_START: int = 22
QUIET_HOURS_END: int = 8
QUIET_HOURS_DELIVER_HOUR: int = 8
QUIET_HOURS_DELIVER_MINUTE: int = 30
DAILY_DIGEST_HOUR: int = 19

# Server-enforced daily quota limits ("Today's Menu" freemium model + fair-use Pro caps)
FREE_DAILY_PLATES: int = 3
PRO_DAILY_PLATES: int = 100
FREE_DAILY_DEEP_DIVES: int = 1
PRO_DAILY_DEEP_DIVES: int = 40
SHARE_BONUS_DEEP_DIVES: int = 1
FREE_DAILY_SUGGESTIONS: int = 10
PRO_DAILY_SUGGESTIONS: int = 100

ALLOWED_CORS_ORIGINS: list[str] = [
    "https://getomakase.app",
    "https://www.getomakase.app",
    "https://gen-lang-client-0120875563.web.app",
    "https://gen-lang-client-0120875563.firebaseapp.com",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

# Gemini built-in safety settings applied to every model call.
# BLOCK_MEDIUM_AND_ABOVE blocks content that is likely or highly likely harmful.
SAFETY_SETTINGS: list[types.SafetySetting] = [
    types.SafetySetting(
        category=types.HarmCategory.HARM_CATEGORY_HARASSMENT,
        threshold=types.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    ),
    types.SafetySetting(
        category=types.HarmCategory.HARM_CATEGORY_HATE_SPEECH,
        threshold=types.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    ),
    types.SafetySetting(
        category=types.HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
        threshold=types.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    ),
    types.SafetySetting(
        category=types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
        threshold=types.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    ),
]

genai_client: Optional[genai.Client] = None
if GEMINI_API_KEY:
    genai_client = genai.Client(api_key=GEMINI_API_KEY)
else:
    logger.warning(
        "GEMINI_API_KEY is not set. Generation endpoints will return an error until it is configured."
    )
