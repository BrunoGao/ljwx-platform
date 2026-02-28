#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-infra}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-sync-service}"
SECRET_NAME="${SECRET_NAME:-sync-service-env}"
APP_NAMESPACE="${APP_NAMESPACE:-argocd}"
APP_NAME="${APP_NAME:-ljwx-platform}"

echo "[检查] sync-service 部署状态"
kubectl get deploy "${DEPLOYMENT_NAME}" -n "${NAMESPACE}" -o wide

echo
echo "[检查] 自动发布关键配置"
for key in \
  DEPLOY_AUTOPR_ENABLED \
  DEPLOY_AUTOPR_BRANCH_PREFIX \
  DEPLOY_AUTOPR_CLOSE_SUPERSEDED_PRS \
  DEPLOY_AUTOPR_AUTO_MERGE_ENABLED \
  DEPLOY_AUTOPR_AUTO_MERGE_METHOD \
  DEPLOY_REPO_OWNER \
  DEPLOY_REPO_NAME \
  DEPLOY_REPO_BASE_BRANCH \
  DEPLOY_REPO_FILE_PATH; do
  value="$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}" | base64 -d || true)"
  if [ -z "${value}" ]; then
    echo "[警告] ${key} 未设置"
  else
    echo "[信息] ${key}=${value}"
  fi
done

echo
echo "[检查] ArgoCD 应用状态"
kubectl get app "${APP_NAME}" -n "${APP_NAMESPACE}" -o jsonpath='{.status.sync.status} {.status.health.status} {.status.sync.revision}{"\n"}'

echo
echo "[检查] 最近 5 分钟自动发布日志"
kubectl logs -n "${NAMESPACE}" deploy/"${DEPLOYMENT_NAME}" --since=5m | rg -n "自动 PR|自动关闭旧 PR|自动合并|task_id" || true

echo
echo "[完成] 检查结束。"
