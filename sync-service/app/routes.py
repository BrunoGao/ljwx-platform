from __future__ import annotations

import asyncio
from fastapi import APIRouter, HTTPException, Request, status
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from starlette.responses import Response

from .config import Settings
from .db import Database
from .models import HealthResponse, SyncAcceptedResponse, SyncWebhookPayload
from .security import verify_bearer, verify_webhook_signature

router = APIRouter()

webhook_total = Counter("sync_webhook_total", "Webhook 接收总次数", ["result"])


def _resolve_target_repo(payload: SyncWebhookPayload, settings: Settings) -> str:
    image_name = payload.image.split("/")[-1]
    return f"{settings.harbor_registry}/{settings.harbor_project}/{image_name}"


@router.post("/sync", response_model=SyncAcceptedResponse)
async def sync_webhook(request: Request) -> SyncAcceptedResponse:
    settings = request.app.state.settings
    db = request.app.state.db
    if not isinstance(settings, Settings) or not isinstance(db, Database):
        raise HTTPException(status_code=500, detail="服务内部状态异常")

    verify_bearer(request, settings)

    body = await asyncio.wait_for(request.body(), timeout=5.0)
    signature = verify_webhook_signature(request, body, settings)

    try:
        payload = SyncWebhookPayload.model_validate_json(body)
    except ValueError as exc:
        webhook_total.labels(result="invalid_payload").inc()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="请求体格式错误或字段不完整",
        ) from exc

    target_repo = _resolve_target_repo(payload, settings)
    task_id, task_status, deduplicated = db.insert_event_and_task(
        payload, signature, target_repo
    )
    webhook_total.labels(result="deduplicated" if deduplicated else "accepted").inc()

    return SyncAcceptedResponse(
        task_id=task_id, status=task_status, deduplicated=deduplicated
    )


@router.get("/healthz", response_model=HealthResponse)
async def healthz(request: Request) -> HealthResponse:
    db = request.app.state.db
    if not isinstance(db, Database):
        raise HTTPException(status_code=500, detail="服务内部状态异常")
    db_ok = db.healthcheck()
    return HealthResponse(status="ok" if db_ok else "degraded", db_ok=db_ok)


@router.get("/metrics")
async def metrics() -> Response:
    payload = generate_latest()
    return Response(content=payload, media_type=CONTENT_TYPE_LATEST)


@router.get("/tasks/{task_id}")
async def task_detail(task_id: str, request: Request) -> dict[str, object]:
    db = request.app.state.db
    if not isinstance(db, Database):
        raise HTTPException(status_code=500, detail="服务内部状态异常")

    detail = db.get_task_detail(task_id)
    if detail is None:
        raise HTTPException(status_code=404, detail="任务不存在")
    return detail.model_dump(mode="json")
