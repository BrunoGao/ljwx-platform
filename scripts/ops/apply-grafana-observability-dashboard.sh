#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

NAMESPACE="${NAMESPACE:-monitoring}"
CONFIGMAP_NAME="${CONFIGMAP_NAME:-ljwx-platform-observability-dashboard}"
DASHBOARD_FILE="${DASHBOARD_FILE:-${PROJECT_ROOT}/k8s/grafana-dashboard-observability.json}"
KEY_NAME="${KEY_NAME:-ljwx-platform-observability.json}"

if [ ! -f "${DASHBOARD_FILE}" ]; then
  echo "[致命] 仪表盘文件不存在: ${DASHBOARD_FILE}"
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  jq empty "${DASHBOARD_FILE}" >/dev/null
else
  echo "[警告] 未安装 jq，跳过 JSON 语法校验"
fi

echo "[信息] 应用 Grafana Dashboard ConfigMap: ${NAMESPACE}/${CONFIGMAP_NAME}"
kubectl create configmap "${CONFIGMAP_NAME}" \
  -n "${NAMESPACE}" \
  --from-file="${KEY_NAME}=${DASHBOARD_FILE}" \
  --dry-run=client -o yaml \
  | kubectl apply -f -

kubectl label configmap "${CONFIGMAP_NAME}" -n "${NAMESPACE}" grafana_dashboard=1 --overwrite >/dev/null
kubectl label configmap "${CONFIGMAP_NAME}" -n "${NAMESPACE}" app.kubernetes.io/name=ljwx-platform --overwrite >/dev/null
kubectl label configmap "${CONFIGMAP_NAME}" -n "${NAMESPACE}" app.kubernetes.io/component=observability --overwrite >/dev/null

echo "[完成] Dashboard ConfigMap 已更新"
echo "[检查] kubectl get cm ${CONFIGMAP_NAME} -n ${NAMESPACE} -o yaml | head -n 40"
echo "[检查] kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=grafana"
echo "[提示] 如 Grafana 未自动加载，请在 UI -> Dashboards -> Import 导入文件: ${DASHBOARD_FILE}"
