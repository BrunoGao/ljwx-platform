from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Iterator
from uuid import uuid4

from .models import SyncWebhookPayload, TaskDetail, TaskStatus


@dataclass(frozen=True)
class TaskRecord:
    id: int
    task_id: str
    event_id: str
    repository: str
    image: str
    digest: str
    tags: list[str]
    target_repo: str
    status: TaskStatus
    retry_count: int
    next_retry_at: datetime | None
    last_error: str | None


class Database:
    def __init__(self, sqlite_path: Path) -> None:
        self._sqlite_path = sqlite_path
        self._sqlite_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_schema()

    @contextmanager
    def _connect(self) -> Iterator[sqlite3.Connection]:
        conn = sqlite3.connect(self._sqlite_path, timeout=5.0, isolation_level=None)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        try:
            yield conn
        finally:
            conn.close()

    def _init_schema(self) -> None:
        with self._connect() as conn:
            conn.executescript(
                """
                CREATE TABLE IF NOT EXISTS webhook_events (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  event_id TEXT NOT NULL UNIQUE,
                  signature TEXT,
                  received_at TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS tasks (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  task_id TEXT NOT NULL UNIQUE,
                  event_id TEXT NOT NULL,
                  repository TEXT NOT NULL,
                  image TEXT NOT NULL,
                  digest TEXT NOT NULL,
                  tags_json TEXT NOT NULL,
                  target_repo TEXT NOT NULL,
                  status TEXT NOT NULL,
                  retry_count INTEGER NOT NULL DEFAULT 0,
                  next_retry_at TEXT,
                  last_error TEXT,
                  created_at TEXT NOT NULL,
                  updated_at TEXT NOT NULL,
                  verified_at TEXT,
                  UNIQUE(repository, image, digest, target_repo)
                );

                CREATE INDEX IF NOT EXISTS idx_tasks_status_next_retry
                ON tasks(status, next_retry_at);
                """
            )

    def healthcheck(self) -> bool:
        with self._connect() as conn:
            row = conn.execute("SELECT 1 AS ok").fetchone()
            return row is not None and int(row["ok"]) == 1

    def insert_event_and_task(
        self,
        payload: SyncWebhookPayload,
        signature: str,
        target_repo: str,
    ) -> tuple[str, TaskStatus, bool]:
        now = datetime.now(UTC).isoformat()
        task_id = f"task-{uuid4()}"
        tags_json = json.dumps(payload.tags, ensure_ascii=True)

        with self._connect() as conn:
            conn.execute("BEGIN IMMEDIATE")
            try:
                conn.execute(
                    """
                    INSERT INTO webhook_events(event_id, signature, received_at)
                    VALUES(?, ?, ?)
                    """,
                    (payload.event_id, signature, now),
                )
            except sqlite3.IntegrityError:
                existing = conn.execute(
                    "SELECT task_id, status FROM tasks WHERE event_id = ?",
                    (payload.event_id,),
                ).fetchone()
                conn.execute("COMMIT")
                if existing is None:
                    raise
                return (
                    str(existing["task_id"]),
                    TaskStatus(str(existing["status"])),
                    True,
                )

            try:
                conn.execute(
                    """
                    INSERT INTO tasks(
                      task_id, event_id, repository, image, digest, tags_json,
                      target_repo, status, retry_count, next_retry_at, last_error,
                      created_at, updated_at, verified_at
                    ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, 0, NULL, NULL, ?, ?, NULL)
                    """,
                    (
                        task_id,
                        payload.event_id,
                        payload.repository,
                        payload.image,
                        payload.digest,
                        tags_json,
                        target_repo,
                        TaskStatus.PENDING.value,
                        now,
                        now,
                    ),
                )
                conn.execute("COMMIT")
                return task_id, TaskStatus.PENDING, False
            except sqlite3.IntegrityError:
                existing = conn.execute(
                    """
                    SELECT task_id, status
                    FROM tasks
                    WHERE repository = ? AND image = ? AND digest = ? AND target_repo = ?
                    """,
                    (payload.repository, payload.image, payload.digest, target_repo),
                ).fetchone()
                conn.execute("COMMIT")
                if existing is None:
                    raise
                return (
                    str(existing["task_id"]),
                    TaskStatus(str(existing["status"])),
                    True,
                )

    def get_task_detail(self, task_id: str) -> TaskDetail | None:
        with self._connect() as conn:
            row = conn.execute(
                """
                SELECT task_id, event_id, repository, image, digest, tags_json, target_repo,
                       status, retry_count, next_retry_at, last_error,
                       created_at, updated_at, verified_at
                FROM tasks
                WHERE task_id = ?
                """,
                (task_id,),
            ).fetchone()
            if row is None:
                return None
            return self._to_task_detail(row)

    def claim_next_task(self, now: datetime) -> TaskRecord | None:
        now_iso = now.isoformat()
        with self._connect() as conn:
            conn.execute("BEGIN IMMEDIATE")
            row = conn.execute(
                """
                SELECT id, task_id, event_id, repository, image, digest, tags_json, target_repo,
                       status, retry_count, next_retry_at, last_error
                FROM tasks
                WHERE status = ? OR (status = ? AND COALESCE(next_retry_at, '') <= ?)
                ORDER BY id ASC
                LIMIT 1
                """,
                (TaskStatus.PENDING.value, TaskStatus.FAILED_RETRYABLE.value, now_iso),
            ).fetchone()
            if row is None:
                conn.execute("COMMIT")
                return None

            updated = conn.execute(
                """
                UPDATE tasks
                SET status = ?, updated_at = ?, last_error = NULL
                WHERE id = ? AND status IN (?, ?)
                """,
                (
                    TaskStatus.SYNCING.value,
                    now_iso,
                    int(row["id"]),
                    TaskStatus.PENDING.value,
                    TaskStatus.FAILED_RETRYABLE.value,
                ),
            )
            if updated.rowcount != 1:
                conn.execute("COMMIT")
                return None
            conn.execute("COMMIT")
            return self._to_task_record(row, TaskStatus.SYNCING)

    def set_verified(self, task_id: str, verified_at: datetime) -> None:
        ts = verified_at.isoformat()
        with self._connect() as conn:
            conn.execute(
                """
                UPDATE tasks
                SET status = ?, updated_at = ?, verified_at = ?, last_error = NULL
                WHERE task_id = ?
                """,
                (TaskStatus.VERIFIED.value, ts, ts, task_id),
            )

    def set_failed_retryable(
        self,
        task_id: str,
        retry_count: int,
        delay_seconds: int,
        error: str,
        now: datetime,
    ) -> None:
        next_retry = now + timedelta(seconds=delay_seconds)
        now_iso = now.isoformat()
        with self._connect() as conn:
            conn.execute(
                """
                UPDATE tasks
                SET status = ?, retry_count = ?, next_retry_at = ?, last_error = ?, updated_at = ?
                WHERE task_id = ?
                """,
                (
                    TaskStatus.FAILED_RETRYABLE.value,
                    retry_count,
                    next_retry.isoformat(),
                    error,
                    now_iso,
                    task_id,
                ),
            )

    def set_failed_fatal(self, task_id: str, error: str, now: datetime) -> None:
        now_iso = now.isoformat()
        with self._connect() as conn:
            conn.execute(
                """
                UPDATE tasks
                SET status = ?, last_error = ?, updated_at = ?
                WHERE task_id = ?
                """,
                (TaskStatus.FAILED_FATAL.value, error, now_iso, task_id),
            )

    @staticmethod
    def _parse_ts(value: str | None) -> datetime | None:
        if value is None or value == "":
            return None
        return datetime.fromisoformat(value)

    def _to_task_record(
        self, row: sqlite3.Row, override_status: TaskStatus | None = None
    ) -> TaskRecord:
        status = override_status or TaskStatus(str(row["status"]))
        return TaskRecord(
            id=int(row["id"]),
            task_id=str(row["task_id"]),
            event_id=str(row["event_id"]),
            repository=str(row["repository"]),
            image=str(row["image"]),
            digest=str(row["digest"]),
            tags=list(json.loads(str(row["tags_json"]))),
            target_repo=str(row["target_repo"]),
            status=status,
            retry_count=int(row["retry_count"]),
            next_retry_at=self._parse_ts(row["next_retry_at"]),
            last_error=str(row["last_error"])
            if row["last_error"] is not None
            else None,
        )

    def _to_task_detail(self, row: sqlite3.Row) -> TaskDetail:
        return TaskDetail(
            task_id=str(row["task_id"]),
            event_id=str(row["event_id"]),
            repository=str(row["repository"]),
            image=str(row["image"]),
            digest=str(row["digest"]),
            tags=list(json.loads(str(row["tags_json"]))),
            target_repo=str(row["target_repo"]),
            status=TaskStatus(str(row["status"])),
            retry_count=int(row["retry_count"]),
            next_retry_at=self._parse_ts(row["next_retry_at"]),
            last_error=str(row["last_error"])
            if row["last_error"] is not None
            else None,
            created_at=datetime.fromisoformat(str(row["created_at"])),
            updated_at=datetime.fromisoformat(str(row["updated_at"])),
            verified_at=self._parse_ts(row["verified_at"]),
        )
