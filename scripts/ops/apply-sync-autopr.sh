#!/usr/bin/env bash
set -euo pipefail

# Required
: "${GITHUB_TOKEN:?请先设置 GITHUB_TOKEN}"

# Optional with defaults
NAMESPACE="${NAMESPACE:-infra}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-sync-service}"
SECRET_NAME="${SECRET_NAME:-sync-service-env}"
DEPLOY_AUTOPR_ENABLED="${DEPLOY_AUTOPR_ENABLED:-true}"
DEPLOY_AUTOPR_BRANCH_PREFIX="${DEPLOY_AUTOPR_BRANCH_PREFIX:-sync}"
DEPLOY_AUTOPR_CLOSE_SUPERSEDED_PRS="${DEPLOY_AUTOPR_CLOSE_SUPERSEDED_PRS:-true}"
DEPLOY_AUTOPR_AUTO_MERGE_ENABLED="${DEPLOY_AUTOPR_AUTO_MERGE_ENABLED:-false}"
DEPLOY_AUTOPR_AUTO_MERGE_METHOD="${DEPLOY_AUTOPR_AUTO_MERGE_METHOD:-squash}"
DEPLOY_REPO_OWNER="${DEPLOY_REPO_OWNER:-BrunoGaoSZ}"
DEPLOY_REPO_NAME="${DEPLOY_REPO_NAME:-ljwx-deploy}"
DEPLOY_REPO_BASE_BRANCH="${DEPLOY_REPO_BASE_BRANCH:-main}"
DEPLOY_REPO_FILE_PATH="${DEPLOY_REPO_FILE_PATH:-apps/ljwx-platform/overlays/prod/kustomization.yaml}"

echo "[信息] 写入 ${NAMESPACE}/${SECRET_NAME} 自动发布配置..."
kubectl patch secret "${SECRET_NAME}" -n "${NAMESPACE}" --type merge -p "$(
  jq -nc \
    --arg enabled "${DEPLOY_AUTOPR_ENABLED}" \
    --arg token "${GITHUB_TOKEN}" \
    --arg prefix "${DEPLOY_AUTOPR_BRANCH_PREFIX}" \
    --arg close_old "${DEPLOY_AUTOPR_CLOSE_SUPERSEDED_PRS}" \
    --arg merge_enabled "${DEPLOY_AUTOPR_AUTO_MERGE_ENABLED}" \
    --arg merge_method "${DEPLOY_AUTOPR_AUTO_MERGE_METHOD}" \
    --arg owner "${DEPLOY_REPO_OWNER}" \
    --arg repo "${DEPLOY_REPO_NAME}" \
    --arg base_branch "${DEPLOY_REPO_BASE_BRANCH}" \
    --arg file_path "${DEPLOY_REPO_FILE_PATH}" \
    '{
      stringData: {
        DEPLOY_AUTOPR_ENABLED: $enabled,
        DEPLOY_AUTOPR_GITHUB_TOKEN: $token,
        DEPLOY_AUTOPR_BRANCH_PREFIX: $prefix,
        DEPLOY_AUTOPR_CLOSE_SUPERSEDED_PRS: $close_old,
        DEPLOY_AUTOPR_AUTO_MERGE_ENABLED: $merge_enabled,
        DEPLOY_AUTOPR_AUTO_MERGE_METHOD: $merge_method,
        DEPLOY_REPO_OWNER: $owner,
        DEPLOY_REPO_NAME: $repo,
        DEPLOY_REPO_BASE_BRANCH: $base_branch,
        DEPLOY_REPO_FILE_PATH: $file_path
      }
    }'
)"

echo "[信息] 重启 ${NAMESPACE}/${DEPLOYMENT_NAME}..."
kubectl rollout restart deploy/"${DEPLOYMENT_NAME}" -n "${NAMESPACE}"
kubectl rollout status deploy/"${DEPLOYMENT_NAME}" -n "${NAMESPACE}" --timeout=180s

echo "[完成] 自动发布配置已生效。"
