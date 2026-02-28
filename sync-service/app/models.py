from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, StringConstraints


class TaskStatus(str, Enum):
    PENDING = "PENDING"
    SYNCING = "SYNCING"
    VERIFIED = "VERIFIED"
    FAILED_RETRYABLE = "FAILED_RETRYABLE"
    FAILED_FATAL = "FAILED_FATAL"


ShaDigest = Annotated[str, StringConstraints(pattern=r"^sha256:[a-f0-9]{64}$")]


class SyncWebhookPayload(BaseModel):
    model_config = ConfigDict(frozen=True)

    event_id: Annotated[str, StringConstraints(min_length=1, max_length=200)]
    repository: Annotated[str, StringConstraints(min_length=1, max_length=255)]
    image: Annotated[str, StringConstraints(min_length=1, max_length=512)]
    git_sha: Annotated[str, StringConstraints(min_length=7, max_length=64)]
    short_sha: Annotated[str, StringConstraints(min_length=7, max_length=12)]
    branch: Annotated[str, StringConstraints(min_length=1, max_length=255)]
    digest: ShaDigest
    tags: list[Annotated[str, StringConstraints(min_length=1, max_length=255)]] = Field(
        default_factory=list,
        min_length=1,
    )
    triggered_at: datetime
    component: Annotated[str, StringConstraints(min_length=1, max_length=64)] | None = (
        None
    )


class SyncAcceptedResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    task_id: str
    status: TaskStatus
    deduplicated: bool


class HealthResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    status: str
    db_ok: bool


class TaskDetail(BaseModel):
    model_config = ConfigDict(frozen=True)

    task_id: str
    event_id: str
    repository: str
    image: str
    digest: str
    tags: list[str] = Field(default_factory=list)
    target_repo: str
    status: TaskStatus
    retry_count: int
    next_retry_at: datetime | None = None
    last_error: str | None = None
    created_at: datetime
    updated_at: datetime
    verified_at: datetime | None = None
