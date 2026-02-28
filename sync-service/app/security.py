from __future__ import annotations

import hashlib
import hmac
from datetime import UTC, datetime

from fastapi import HTTPException, Request, status

from .config import Settings


def verify_bearer(request: Request, settings: Settings) -> None:
    token = request.headers.get("Authorization", "")
    expected = f"Bearer {settings.sync_bearer_token}"
    if not hmac.compare_digest(token, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="鉴权失败：Bearer Token 无效",
        )


def verify_webhook_signature(request: Request, body: bytes, settings: Settings) -> str:
    ts = request.headers.get("X-Sync-Timestamp", "")
    raw_signature = request.headers.get("X-Sync-Signature", "")
    if ts == "" or raw_signature == "":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="鉴权失败：缺少签名头",
        )

    if not raw_signature.startswith("sha256="):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="鉴权失败：签名格式非法",
        )

    try:
        ts_int = int(ts)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="鉴权失败：时间戳非法",
        ) from exc

    now = int(datetime.now(UTC).timestamp())
    skew = abs(now - ts_int)
    if skew > settings.webhook_max_skew_seconds:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="鉴权失败：请求时间窗超限",
        )

    signed = f"{ts}.".encode("utf-8") + body
    expected = hmac.new(
        settings.sync_hmac_secret.encode("utf-8"),
        signed,
        hashlib.sha256,
    ).hexdigest()
    actual = raw_signature.replace("sha256=", "", 1)
    if not hmac.compare_digest(expected, actual):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="鉴权失败：签名不匹配",
        )

    return raw_signature
