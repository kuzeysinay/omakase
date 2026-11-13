"""Letterboxd RSS fetching and XML parsing hardened against SSRF and Entity Expansion."""

from __future__ import annotations

import asyncio
import re
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import xml.etree.ElementTree as ET

from fastapi import HTTPException

from app.config import logger
from app.schemas import LetterboxdFilmsRequest
from app.security import _MAX_RSS_BYTES, _sanitize_single_line


def _parse_letterboxd_rss(xml_bytes: bytes, *, limit: int = 50) -> list[dict]:
    """Parse Letterboxd RSS XML into a list of film dicts, rejecting DTD/Entity payloads."""
    upper_head = xml_bytes[:4096].upper()
    if b"<!DOCTYPE" in upper_head or b"<!ENTITY" in xml_bytes.upper():
        raise ValueError("Unsafe XML declarations are not permitted.")

    root = ET.fromstring(xml_bytes)
    channel = root.find("channel")
    if channel is None:
        return []

    films: list[dict] = []
    for item in channel.findall("item"):
        title = item.findtext("{https://letterboxd.com}filmTitle", "")
        if not title:
            raw_title = item.findtext("title", "")
            title = re.sub(r"\s*,\s*\d{4}\s*-\s*★.*$", "", raw_title).strip()
        year = item.findtext("{https://letterboxd.com}filmYear", "")
        rating = item.findtext("{https://letterboxd.com}memberRating", "")
        watched = item.findtext("{https://letterboxd.com}watchedDate", "")

        films.append(
            {
                "title": _sanitize_single_line(title, 200),
                "year": int(year) if year and year.isdigit() else None,
                "rating": float(rating) if rating else None,
                "watched_date": _sanitize_single_line(watched, 20) if watched else None,
            }
        )
        if len(films) >= limit:
            break
    return films


async def fetch_letterboxd_films(req: LetterboxdFilmsRequest) -> list[dict]:
    """Fetch a user's recently watched films from their Letterboxd RSS feed."""
    rss_url = f"https://letterboxd.com/{req.username}/rss/"
    logger.info("Fetching Letterboxd RSS for user %r", req.username)

    def _fetch() -> bytes:
        request = Request(
            rss_url,
            headers={
                "User-Agent": "Omakase/1.0 (https://github.com/omakase-app)",
                "Accept": "application/rss+xml, application/xml, text/xml",
            },
        )
        try:
            with urlopen(request, timeout=10) as resp:
                final_url = resp.geturl() or ""
                if not final_url.startswith("https://letterboxd.com/"):
                    raise ValueError("Unexpected redirect target from Letterboxd.")
                data = resp.read(_MAX_RSS_BYTES + 1)
                if len(data) > _MAX_RSS_BYTES:
                    raise ValueError(
                        "Letterboxd RSS response exceeded maximum allowed size."
                    )
                return data
        except HTTPError as exc:
            if exc.code == 404:
                raise ValueError(
                    f"Letterboxd user '{req.username}' not found."
                ) from exc
            raise ValueError(f"Letterboxd returned HTTP {exc.code}.") from exc
        except URLError as exc:
            raise ValueError("Could not reach Letterboxd.") from exc

    try:
        xml_bytes = await asyncio.to_thread(_fetch)
        return _parse_letterboxd_rss(xml_bytes, limit=req.limit)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:  # noqa: BLE001
        logger.warning("Letterboxd fetch failed: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Failed to fetch Letterboxd data.",
        ) from exc
