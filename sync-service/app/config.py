from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = Field(default="prod", alias="APP_ENV")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")
    sqlite_path: Path = Field(default=Path("/data/sync.db"), alias="SQLITE_PATH")

    sync_hmac_secret: str = Field(alias="SYNC_HMAC_SECRET")
    sync_bearer_token: str = Field(alias="SYNC_BEARER_TOKEN")
    webhook_max_skew_seconds: int = Field(default=300, alias="WEBHOOK_MAX_SKEW_SECONDS")

    ghcr_registry: str = Field(default="ghcr.io", alias="GHCR_REGISTRY")
    ghcr_username: str = Field(alias="GHCR_USERNAME")
    ghcr_token: str = Field(alias="GHCR_TOKEN")

    harbor_registry: str = Field(
        default="harbor.eu.lingjingwanxiang.cn", alias="HARBOR_REGISTRY"
    )
    harbor_username: str = Field(alias="HARBOR_USERNAME")
    harbor_password: str = Field(alias="HARBOR_PASSWORD")
    harbor_project: str = Field(default="ci", alias="HARBOR_PROJECT")
    harbor_tls_verify: bool = Field(default=True, alias="HARBOR_TLS_VERIFY")

    skopeo_bin: str = Field(default="/usr/bin/skopeo", alias="SKOPEO_BIN")
    skopeo_timeout_seconds: int = Field(default=600, alias="SKOPEO_TIMEOUT_SECONDS")

    worker_poll_seconds: int = Field(default=3, alias="WORKER_POLL_SECONDS")
    max_retries: int = Field(default=6, alias="MAX_RETRIES")
    retry_base_seconds: int = Field(default=10, alias="RETRY_BASE_SECONDS")
    retry_max_seconds: int = Field(default=600, alias="RETRY_MAX_SECONDS")

    deploy_autopr_enabled: bool = Field(default=False, alias="DEPLOY_AUTOPR_ENABLED")
    deploy_autopr_github_token: str = Field(
        default="", alias="DEPLOY_AUTOPR_GITHUB_TOKEN"
    )
    deploy_autopr_timeout_seconds: int = Field(
        default=10, alias="DEPLOY_AUTOPR_TIMEOUT_SECONDS"
    )
    deploy_autopr_branch_prefix: str = Field(
        default="sync", alias="DEPLOY_AUTOPR_BRANCH_PREFIX"
    )
    deploy_autopr_close_superseded_prs: bool = Field(
        default=True, alias="DEPLOY_AUTOPR_CLOSE_SUPERSEDED_PRS"
    )
    deploy_autopr_auto_merge_enabled: bool = Field(
        default=False, alias="DEPLOY_AUTOPR_AUTO_MERGE_ENABLED"
    )
    deploy_autopr_auto_merge_method: str = Field(
        default="squash", alias="DEPLOY_AUTOPR_AUTO_MERGE_METHOD"
    )
    deploy_repo_owner: str = Field(default="BrunoGaoSZ", alias="DEPLOY_REPO_OWNER")
    deploy_repo_name: str = Field(default="ljwx-deploy", alias="DEPLOY_REPO_NAME")
    deploy_repo_base_branch: str = Field(
        default="main", alias="DEPLOY_REPO_BASE_BRANCH"
    )
    deploy_repo_file_path: str = Field(
        default="apps/ljwx-platform/overlays/prod/kustomization.yaml",
        alias="DEPLOY_REPO_FILE_PATH",
    )


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
