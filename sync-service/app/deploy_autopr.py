from __future__ import annotations

import base64
import json
import logging
import re
from dataclasses import dataclass
from typing import Final
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

from .config import Settings
from .db import TaskRecord

logger = logging.getLogger(__name__)

_GITHUB_API_BASE: Final[str] = "https://api.github.com"
_ALLOWED_COMPONENTS: Final[set[str]] = {
    "ljwx-platform",
    "ljwx-platform-admin-ui",
    "ljwx-platform-screen",
}


class DeployAutoPrError(Exception):
    pass


@dataclass(frozen=True)
class _RepoFile:
    sha: str
    content: str


class DeployRepoAutoPr:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def submit_verified_task(self, task: TaskRecord) -> None:
        if not self._settings.deploy_autopr_enabled:
            return
        if self._settings.deploy_autopr_github_token in ("", "replace_me"):
            logger.warning(
                "自动 PR 已启用但缺少 GitHub Token，跳过 task_id=%s", task.task_id
            )
            return

        sha_tag = self._extract_sha_tag(task.tags)
        if sha_tag is None:
            logger.warning("任务缺少 sha-* 标签，跳过自动 PR task_id=%s", task.task_id)
            return

        component = task.target_repo.rsplit("/", 1)[-1]
        if component not in _ALLOWED_COMPONENTS:
            logger.info("任务组件不在自动发布白名单，跳过 component=%s", component)
            return

        branch = f"{self._settings.deploy_autopr_branch_prefix}/{component}/{sha_tag}"
        owner = self._settings.deploy_repo_owner
        repo = self._settings.deploy_repo_name
        file_path = self._settings.deploy_repo_file_path

        base_sha = self._fetch_branch_sha(
            owner, repo, self._settings.deploy_repo_base_branch
        )
        self._ensure_branch(owner, repo, branch, base_sha)
        repo_file = self._fetch_file(owner, repo, file_path, branch)
        updated_content = self._update_component_tag(
            repo_file.content, component, sha_tag
        )

        if updated_content == repo_file.content:
            logger.info(
                "deploy 文件已是目标版本，无需提交 task_id=%s component=%s tag=%s",
                task.task_id,
                component,
                sha_tag,
            )
            return

        commit_message = f"chore(deploy): {component} -> {sha_tag}"
        self._update_file(
            owner,
            repo,
            file_path,
            branch,
            repo_file.sha,
            updated_content,
            commit_message,
        )

        title = f"chore(deploy): {component} -> {sha_tag}"
        body = (
            "## 自动同步\n"
            f"- task_id: `{task.task_id}`\n"
            f"- component: `{component}`\n"
            f"- image: `{task.image}`\n"
            f"- digest: `{task.digest}`\n"
            f"- tag: `{sha_tag}`\n"
        )
        self._create_or_reuse_pr(
            owner=owner,
            repo=repo,
            head_branch=branch,
            base_branch=self._settings.deploy_repo_base_branch,
            title=title,
            body=body,
        )
        logger.info(
            "自动 PR 已准备完成 task_id=%s component=%s tag=%s branch=%s",
            task.task_id,
            component,
            sha_tag,
            branch,
        )

    @staticmethod
    def _extract_sha_tag(tags: list[str]) -> str | None:
        for tag in tags:
            if tag.startswith("sha-") and len(tag) > 4:
                return tag
        return None

    def _update_component_tag(self, content: str, component: str, sha_tag: str) -> str:
        escaped_repo = re.escape(f"harbor.eu.lingjingwanxiang.cn/ljwx/{component}")
        pattern = (
            rf"(?ms)(- name:\s+[^\n]+\n"
            rf"\s+newName:\s+{escaped_repo}\n"
            rf"\s+newTag:\s+)([^\n]+)"
        )
        updated, count = re.subn(pattern, rf"\1{sha_tag}", content, count=1)
        if count == 0:
            raise DeployAutoPrError(
                f"未在 deploy 文件中找到组件映射: component={component}"
            )
        return updated

    def _fetch_branch_sha(self, owner: str, repo: str, branch: str) -> str:
        data = self._request_json(
            "GET", f"/repos/{owner}/{repo}/git/ref/heads/{branch}"
        )
        obj = self._as_dict(data)
        obj_ref = self._as_dict(obj.get("object"))
        sha = obj_ref.get("sha")
        if not isinstance(sha, str) or sha == "":
            raise DeployAutoPrError("无法读取分支 SHA")
        return sha

    def _ensure_branch(self, owner: str, repo: str, branch: str, base_sha: str) -> None:
        payload = {"ref": f"refs/heads/{branch}", "sha": base_sha}
        try:
            self._request_json("POST", f"/repos/{owner}/{repo}/git/refs", payload)
        except DeployAutoPrError as exc:
            if "Reference already exists" in str(exc):
                return
            raise

    def _fetch_file(self, owner: str, repo: str, path: str, ref: str) -> _RepoFile:
        encoded_path = quote(path, safe="/")
        data = self._request_json(
            "GET", f"/repos/{owner}/{repo}/contents/{encoded_path}?ref={quote(ref)}"
        )
        obj = self._as_dict(data)
        sha = obj.get("sha")
        content = obj.get("content")
        if not isinstance(sha, str) or sha == "":
            raise DeployAutoPrError("读取 deploy 文件失败：缺少 sha")
        if not isinstance(content, str) or content == "":
            raise DeployAutoPrError("读取 deploy 文件失败：缺少内容")
        decoded = base64.b64decode(content).decode("utf-8")
        return _RepoFile(sha=sha, content=decoded)

    def _update_file(
        self,
        owner: str,
        repo: str,
        path: str,
        branch: str,
        current_sha: str,
        content: str,
        message: str,
    ) -> None:
        encoded_path = quote(path, safe="/")
        payload = {
            "message": message,
            "content": base64.b64encode(content.encode("utf-8")).decode("ascii"),
            "sha": current_sha,
            "branch": branch,
        }
        self._request_json(
            "PUT", f"/repos/{owner}/{repo}/contents/{encoded_path}", payload
        )

    def _create_or_reuse_pr(
        self,
        owner: str,
        repo: str,
        head_branch: str,
        base_branch: str,
        title: str,
        body: str,
    ) -> None:
        payload = {
            "title": title,
            "head": head_branch,
            "base": base_branch,
            "body": body,
        }
        try:
            self._request_json("POST", f"/repos/{owner}/{repo}/pulls", payload)
        except DeployAutoPrError as exc:
            if "A pull request already exists" in str(exc):
                logger.info("自动 PR 已存在，分支=%s", head_branch)
                return
            raise

    def _request_json(
        self, method: str, path: str, payload: dict[str, str] | None = None
    ) -> object:
        token = self._settings.deploy_autopr_github_token
        url = f"{_GITHUB_API_BASE}{path}"
        data: bytes | None = None
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "sync-service-autopr",
        }
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
            headers["Content-Type"] = "application/json"

        request = Request(url=url, data=data, headers=headers, method=method)
        try:
            with urlopen(
                request, timeout=float(self._settings.deploy_autopr_timeout_seconds)
            ) as response:
                raw = response.read().decode("utf-8")
                if raw == "":
                    return {}
                return json.loads(raw)
        except HTTPError as exc:
            body = exc.read().decode("utf-8")
            raise DeployAutoPrError(
                f"GitHub API 调用失败 status={exc.code} body={body}"
            ) from exc
        except URLError as exc:
            raise DeployAutoPrError(f"GitHub API 网络异常: {str(exc)}") from exc
        except ValueError as exc:
            raise DeployAutoPrError(f"GitHub API 返回解析失败: {str(exc)}") from exc

    @staticmethod
    def _as_dict(value: object) -> dict[str, object]:
        if not isinstance(value, dict):
            raise DeployAutoPrError("GitHub API 返回结构不符合预期")
        return value
