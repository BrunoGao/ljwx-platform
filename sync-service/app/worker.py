from __future__ import annotations

import asyncio
import logging
from datetime import UTC, datetime

from .config import Settings
from .db import Database, TaskRecord
from .deploy_autopr import DeployAutoPrError, DeployRepoAutoPr
from .skopeo_runner import FatalError, RetryableError, SkopeoRunner

logger = logging.getLogger(__name__)


class WorkerService:
    def __init__(
        self,
        db: Database,
        skopeo: SkopeoRunner,
        settings: Settings,
        deploy_autopr: DeployRepoAutoPr | None = None,
    ) -> None:
        self._db = db
        self._skopeo = skopeo
        self._settings = settings
        self._deploy_autopr = deploy_autopr
        self._stop_event = asyncio.Event()
        self._task: asyncio.Task[None] | None = None

    async def start(self) -> None:
        if self._task is not None:
            return
        self._stop_event.clear()
        self._task = asyncio.create_task(self._run_loop(), name="sync-worker")

    async def stop(self) -> None:
        self._stop_event.set()
        if self._task is not None:
            await self._task
        self._task = None

    async def _run_loop(self) -> None:
        logger.info("同步 Worker 已启动")
        while not self._stop_event.is_set():
            try:
                claimed = self._db.claim_next_task(datetime.now(UTC))
                if claimed is None:
                    await self._sleep_poll_interval()
                    continue
                self._process_one_task(claimed)
            except Exception as exc:  # noqa: BLE001
                logger.exception("Worker 主循环异常: %s", str(exc))
                await self._sleep_poll_interval()
        logger.info("同步 Worker 已停止")

    async def _sleep_poll_interval(self) -> None:
        try:
            await asyncio.wait_for(
                self._stop_event.wait(),
                timeout=float(self._settings.worker_poll_seconds),
            )
        except TimeoutError:
            return

    def _process_one_task(self, task: TaskRecord) -> None:
        now = datetime.now(UTC)
        logger.info(
            "开始处理任务 task_id=%s image=%s digest=%s",
            task.task_id,
            task.image,
            task.digest,
        )
        try:
            if self._skopeo.harbor_has_digest(task):
                self._db.set_verified(task.task_id, now)
                self._trigger_deploy_autopr(task)
                logger.info(
                    "任务已验证完成（目标已存在同 digest） task_id=%s", task.task_id
                )
                return

            self._skopeo.copy_task(task)
            self._skopeo.verify_digest(task)
            self._db.set_verified(task.task_id, datetime.now(UTC))
            self._trigger_deploy_autopr(task)
            logger.info("任务同步并校验成功 task_id=%s", task.task_id)
        except RetryableError as exc:
            retry = task.retry_count + 1
            if retry > self._settings.max_retries:
                message = f"重试耗尽: {str(exc)}"
                self._db.set_failed_fatal(task.task_id, message, datetime.now(UTC))
                logger.error(
                    "任务失败并转为致命错误 task_id=%s error=%s", task.task_id, message
                )
                return

            delay = min(
                self._settings.retry_base_seconds * (2 ** (retry - 1)),
                self._settings.retry_max_seconds,
            )
            self._db.set_failed_retryable(
                task.task_id, retry, delay, str(exc), datetime.now(UTC)
            )
            logger.warning(
                "任务可重试失败 task_id=%s retry=%s delay=%s error=%s",
                task.task_id,
                retry,
                delay,
                str(exc),
            )
        except FatalError as exc:
            self._db.set_failed_fatal(task.task_id, str(exc), datetime.now(UTC))
            logger.error("任务致命失败 task_id=%s error=%s", task.task_id, str(exc))

    def _trigger_deploy_autopr(self, task: TaskRecord) -> None:
        if self._deploy_autopr is None:
            return
        try:
            self._deploy_autopr.submit_verified_task(task)
        except DeployAutoPrError as exc:
            logger.error(
                "自动 deploy PR 失败 task_id=%s error=%s", task.task_id, str(exc)
            )


async def run_worker_forever() -> None:
    settings = Settings()
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper(), logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    db = Database(settings.sqlite_path)
    skopeo = SkopeoRunner(settings)
    deploy_autopr = DeployRepoAutoPr(settings)
    worker = WorkerService(
        db=db, skopeo=skopeo, settings=settings, deploy_autopr=deploy_autopr
    )
    await worker.start()
    try:
        while True:
            await asyncio.sleep(3600)
    except KeyboardInterrupt:
        logger.info("收到终止信号，正在停止 Worker")
    finally:
        await worker.stop()


if __name__ == "__main__":
    asyncio.run(run_worker_forever())
