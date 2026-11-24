"""Protected Mission Control admin endpoints (/admin/*)."""

from __future__ import annotations

from typing import Any, Literal, Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import JSONResponse, PlainTextResponse

from app.schemas import AdminFeedbackUpdateRequest, AdminReportUpdateRequest
from app.security import _check_rate_limit, verify_admin_user
from app.services.admin_service import (
    build_admin_overview,
    build_agent_export,
    list_feedback,
    list_moderation_reports,
    list_recent_users,
    update_feedback,
    update_moderation_report,
)

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/me")
async def admin_me(
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> dict[str, Any]:
    """Confirm admin identity for the Web Mission Control session."""
    return {"is_admin": True, "uid": admin["uid"], "email": admin.get("email") or ""}


@router.get("/overview")
async def admin_overview(
    days: int = Query(default=7, ge=1, le=90),
    refresh_rc: bool = Query(default=False),
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> dict[str, Any]:
    """Return full launch KPIs, funnel, AI unit economics, RevenueCat overview, and insights."""
    _check_rate_limit(admin["caller_id"], bucket="admin_overview", max_calls=30, window_seconds=60)
    return await build_admin_overview(days=days, force_rc_refresh=refresh_rc)


@router.get("/feedback")
async def admin_list_feedback(
    status: str = Query(default="all", max_length=24),
    limit: int = Query(default=50, ge=1, le=200),
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> dict[str, Any]:
    """List user-submitted feedback sorted newest first."""
    _check_rate_limit(admin["caller_id"], bucket="admin_read", max_calls=60, window_seconds=60)
    items = await list_feedback(status=status, limit=limit)
    return {"items": items, "count": len(items)}


@router.patch("/feedback/{feedback_id}")
async def admin_patch_feedback(
    feedback_id: str,
    req: AdminFeedbackUpdateRequest,
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> dict[str, Any]:
    """Update status or admin note on a user feedback item."""
    _check_rate_limit(admin["caller_id"], bucket="admin_write", max_calls=60, window_seconds=60)
    item = await update_feedback(feedback_id, req)
    return {"status": "ok", "item": item}


@router.get("/reports")
async def admin_list_reports(
    status: str = Query(default="all", max_length=24),
    limit: int = Query(default=50, ge=1, le=200),
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> dict[str, Any]:
    """List UGC moderation reports enriched with post previews."""
    _check_rate_limit(admin["caller_id"], bucket="admin_read", max_calls=60, window_seconds=60)
    items = await list_moderation_reports(status=status, limit=limit)
    return {"items": items, "count": len(items)}


@router.patch("/reports/{report_id}")
async def admin_patch_report(
    report_id: str,
    req: AdminReportUpdateRequest,
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> dict[str, Any]:
    """Resolve/dismiss a moderation report and optionally delete the offending post."""
    _check_rate_limit(admin["caller_id"], bucket="admin_write", max_calls=60, window_seconds=60)
    item = await update_moderation_report(report_id, req)
    return {"status": "ok", "item": item}


@router.get("/users")
async def admin_list_users(
    limit: int = Query(default=40, ge=1, le=200),
    search: Optional[str] = Query(default=None, max_length=100),
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> dict[str, Any]:
    """List recent users with subscription tier and today's plate usage."""
    _check_rate_limit(admin["caller_id"], bucket="admin_read", max_calls=60, window_seconds=60)
    items = await list_recent_users(limit=limit, search=search)
    return {"items": items, "count": len(items)}


@router.get("/export")
async def admin_export(
    days: int = Query(default=7, ge=1, le=90),
    format: Literal["json", "markdown"] = Query(default="markdown"),
    preset: Literal["launch", "conversion", "triage", "growth"] = Query(default="launch"),
    admin: dict[str, Any] = Depends(verify_admin_user),
) -> Any:
    """Export an AI-Agent-ready Markdown briefing or structured JSON snapshot."""
    _check_rate_limit(admin["caller_id"], bucket="admin_export", max_calls=20, window_seconds=60)
    payload, markdown_text = await build_agent_export(days=days, preset=preset)
    if format == "json":
        return JSONResponse(content=payload)
    return PlainTextResponse(content=markdown_text, media_type="text/markdown; charset=utf-8")
