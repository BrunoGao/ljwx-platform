from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass

from .config import Settings
from .db import TaskRecord


class RetryableError(Exception):
    pass


class FatalError(Exception):
    pass


@dataclass(frozen=True)
class InspectResult:
    digest: str


class SkopeoRunner:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def harbor_has_digest(self, task: TaskRecord) -> bool:
        target = f"docker://{task.target_repo}@{task.digest}"
        try:
            self._run(
                [
                    self._settings.skopeo_bin,
                    "inspect",
                    f"--creds={self._settings.harbor_username}:{self._settings.harbor_password}",
                    f"--tls-verify={str(self._settings.harbor_tls_verify).lower()}",
                    target,
                ]
            )
            return True
        except RetryableError:
            return False
        except FatalError:
            return False

    def copy_task(self, task: TaskRecord) -> None:
        source = f"docker://{task.image}@{task.digest}"
        for tag in task.tags:
            dest = f"docker://{task.target_repo}:{tag}"
            self._run(
                [
                    self._settings.skopeo_bin,
                    "copy",
                    "--all",
                    f"--src-creds={self._settings.ghcr_username}:{self._settings.ghcr_token}",
                    f"--dest-creds={self._settings.harbor_username}:{self._settings.harbor_password}",
                    "--retry-times=3",
                    "--src-tls-verify=true",
                    f"--dest-tls-verify={str(self._settings.harbor_tls_verify).lower()}",
                    source,
                    dest,
                ]
            )

    def verify_digest(self, task: TaskRecord) -> None:
        for tag in task.tags:
            inspect = self.inspect_target(task.target_repo, tag)
            if inspect.digest != task.digest:
                raise FatalError(
                    f"digest 不一致: tag={tag}, 期望={task.digest}, 实际={inspect.digest}"
                )

    def inspect_target(self, target_repo: str, tag: str) -> InspectResult:
        target = f"docker://{target_repo}:{tag}"
        output = self._run(
            [
                self._settings.skopeo_bin,
                "inspect",
                f"--creds={self._settings.harbor_username}:{self._settings.harbor_password}",
                f"--tls-verify={str(self._settings.harbor_tls_verify).lower()}",
                target,
            ]
        )
        try:
            payload = json.loads(output)
            digest = str(payload.get("Digest", ""))
        except json.JSONDecodeError as exc:
            raise RetryableError("skopeo inspect 返回非 JSON") from exc
        if digest == "":
            raise RetryableError("skopeo inspect 未返回 Digest")
        return InspectResult(digest=digest)

    def _run(self, cmd: list[str]) -> str:
        try:
            completed = subprocess.run(
                cmd,
                check=True,
                text=True,
                capture_output=True,
                timeout=self._settings.skopeo_timeout_seconds,
            )
            return completed.stdout.strip()
        except subprocess.TimeoutExpired as exc:
            raise RetryableError("skopeo 执行超时") from exc
        except FileNotFoundError as exc:
            raise FatalError("未找到 skopeo 可执行文件，请检查 SKOPEO_BIN") from exc
        except subprocess.CalledProcessError as exc:
            stderr = (exc.stderr or "").lower()
            stdout = (exc.stdout or "").lower()
            merged = f"{stdout}\n{stderr}"
            if any(
                token in merged
                for token in [
                    "timeout",
                    "tempor",
                    "tls handshake",
                    "connection reset",
                    "502",
                    "503",
                    "504",
                ]
            ):
                raise RetryableError("registry 网络或服务异常") from exc
            if any(
                token in merged
                for token in [
                    "unauthorized",
                    "denied",
                    "forbidden",
                    "authentication required",
                ]
            ):
                raise FatalError("认证失败，请检查 GHCR/Harbor 凭据") from exc
            if "manifest unknown" in merged or "not found" in merged:
                raise FatalError("镜像或摘要不存在") from exc
            raise RetryableError("skopeo 命令失败") from exc
