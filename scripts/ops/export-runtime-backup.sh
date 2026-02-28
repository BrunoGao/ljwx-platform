#!/usr/bin/env bash
set -euo pipefail

# This script exports runtime state for disaster recovery.
BACKUP_ROOT="${BACKUP_ROOT:-/tmp/ljwx-platform-backup}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${BACKUP_ROOT}/${TS}"

NAMESPACES="${NAMESPACES:-infra ljwx-platform argocd cert-manager}"
SYNC_NAMESPACE="${SYNC_NAMESPACE:-infra}"
SYNC_DEPLOYMENT="${SYNC_DEPLOYMENT:-sync-service}"

mkdir -p "${OUT_DIR}"

echo "[信息] 导出 Kubernetes 关键资源到 ${OUT_DIR}"
for ns in ${NAMESPACES}; do
  mkdir -p "${OUT_DIR}/${ns}"
  kubectl get all -n "${ns}" -o yaml > "${OUT_DIR}/${ns}/all.yaml" || true
  kubectl get secret -n "${ns}" -o yaml > "${OUT_DIR}/${ns}/secrets.yaml" || true
  kubectl get configmap -n "${ns}" -o yaml > "${OUT_DIR}/${ns}/configmaps.yaml" || true
  kubectl get ingress -n "${ns}" -o yaml > "${OUT_DIR}/${ns}/ingress.yaml" || true
done

echo "[信息] 导出 cert-manager 集群级资源"
kubectl get clusterissuer -o yaml > "${OUT_DIR}/clusterissuers.yaml" || true
kubectl get certificate -A -o yaml > "${OUT_DIR}/certificates-all.yaml" || true
kubectl get certificaterequest -A -o yaml > "${OUT_DIR}/certificaterequests-all.yaml" || true

echo "[信息] 导出 sync-service sqlite 数据库"
kubectl exec -n "${SYNC_NAMESPACE}" deploy/"${SYNC_DEPLOYMENT}" -- sh -c 'cat /data/sync.db' > "${OUT_DIR}/sync.db"

echo "[信息] 生成校验信息"
{
  echo "timestamp=${TS}"
  echo "cluster_context=$(kubectl config current-context 2>/dev/null || true)"
  echo "backup_dir=${OUT_DIR}"
} > "${OUT_DIR}/metadata.txt"

echo "[完成] 备份已导出: ${OUT_DIR}"
echo "[提示] 请将该目录同步到异地持久存储（对象存储/NAS/另一台主机）。"
