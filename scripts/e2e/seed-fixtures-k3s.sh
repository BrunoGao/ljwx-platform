#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SQL_FILE="${PROJECT_ROOT}/scripts/e2e/seed-fixtures.sql"

APP_NAMESPACE="${APP_NAMESPACE:-ljwx-platform}"
INFRA_NAMESPACE="${INFRA_NAMESPACE:-infra}"
RUNTIME_CONFIGMAP="${RUNTIME_CONFIGMAP:-ljwx-platform-runtime}"
DB_SECRET_NAME="${DB_SECRET_NAME:-ljwx-platform-db}"
POSTGRES_POD="${POSTGRES_POD:-}"

DB_HOST="${DB_HOST:-}"
DB_PORT="${DB_PORT:-}"
DB_NAME="${DB_NAME:-}"
DB_USERNAME="${DB_USERNAME:-}"
DB_PASSWORD="${DB_PASSWORD:-}"

TENANT_B_ID="${TENANT_B_ID:-200001}"
TENANT_B_ROLE_ID="${TENANT_B_ROLE_ID:-220001}"
TENANT_B_USER_ID="${TENANT_B_USER_ID:-220002}"
TENANT_B_USER="${TENANT_B_USER:-tenantB_admin}"
TENANT_B_PASS="${TENANT_B_PASS:-}"
TENANT_B_PASS_HASH="${TENANT_B_PASS_HASH:-}"

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "缺少依赖命令: ${cmd}" >&2
    exit 1
  fi
}

require_command kubectl
require_command base64
require_command awk

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "未找到 SQL 文件: ${SQL_FILE}" >&2
  exit 1
fi

generate_bcrypt_hash() {
  local password="$1"

  if command -v htpasswd >/dev/null 2>&1; then
    htpasswd -bnBC 10 "" "${password}" | tr -d ':\n'
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    if TENANT_B_PASS="${password}" python3 - <<'PY' >/tmp/ljwx-bcrypt-hash.txt 2>/tmp/ljwx-bcrypt-hash.err
import os
import sys

try:
    import bcrypt
except ModuleNotFoundError as exc:
    print(f"missing dependency: {exc.name}", file=sys.stderr)
    raise SystemExit(1)

raw = os.environ["TENANT_B_PASS"].encode()
print(bcrypt.hashpw(raw, bcrypt.gensalt(rounds=10)).decode())
PY
    then
      cat /tmp/ljwx-bcrypt-hash.txt
      rm -f /tmp/ljwx-bcrypt-hash.txt /tmp/ljwx-bcrypt-hash.err
      return 0
    fi
    rm -f /tmp/ljwx-bcrypt-hash.txt /tmp/ljwx-bcrypt-hash.err
  fi

  if command -v docker >/dev/null 2>&1; then
    docker run --rm httpd:2.4-alpine htpasswd -bnBC 10 "" "${password}" | tr -d ':\n'
    return 0
  fi

  echo "缺少 BCrypt 生成方式，请安装 htpasswd，或提供带 bcrypt 模块的 python3，或安装 docker，或直接传入 TENANT_B_PASS_HASH" >&2
  return 1
}

if [[ -z "${TENANT_B_PASS_HASH}" ]]; then
  if [[ -z "${TENANT_B_PASS}" ]]; then
    echo "缺少 TENANT_B_PASS 或 TENANT_B_PASS_HASH，无法执行夹具修复" >&2
    exit 1
  fi
  TENANT_B_PASS_HASH="$(generate_bcrypt_hash "${TENANT_B_PASS}")"
fi

if [[ -z "${DB_HOST}" ]]; then
  DB_HOST="$(kubectl -n "${APP_NAMESPACE}" get "configmap/${RUNTIME_CONFIGMAP}" -o jsonpath='{.data.DB_HOST}')"
fi
if [[ -z "${DB_PORT}" ]]; then
  DB_PORT="$(kubectl -n "${APP_NAMESPACE}" get "configmap/${RUNTIME_CONFIGMAP}" -o jsonpath='{.data.DB_PORT}')"
fi
if [[ -z "${DB_NAME}" ]]; then
  DB_NAME="$(kubectl -n "${APP_NAMESPACE}" get "configmap/${RUNTIME_CONFIGMAP}" -o jsonpath='{.data.DB_NAME}')"
fi

if [[ -z "${DB_USERNAME}" ]]; then
  DB_USERNAME="$(kubectl -n "${APP_NAMESPACE}" get "secret/${DB_SECRET_NAME}" -o jsonpath='{.data.DB_USERNAME}' | base64 -d)"
fi
if [[ -z "${DB_PASSWORD}" ]]; then
  DB_PASSWORD="$(kubectl -n "${APP_NAMESPACE}" get "secret/${DB_SECRET_NAME}" -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)"
fi

if [[ -z "${POSTGRES_POD}" ]]; then
  POSTGRES_POD="$(kubectl -n "${INFRA_NAMESPACE}" get pods --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | awk -F '\t' '/postgres/{print $1; exit}')"
fi

if [[ -z "${POSTGRES_POD}" ]]; then
  echo "未找到 PostgreSQL Pod，请确认 infra 命名空间可访问" >&2
  exit 1
fi

kubectl -n "${INFRA_NAMESPACE}" exec "${POSTGRES_POD}" -- \
  env PGPASSWORD="${DB_PASSWORD}" \
  psql -v ON_ERROR_STOP=1 \
    -v "tenant_b_id=${TENANT_B_ID}" \
    -v "tenant_b_role_id=${TENANT_B_ROLE_ID}" \
    -v "tenant_b_user_id=${TENANT_B_USER_ID}" \
    -v "tenant_b_user=${TENANT_B_USER}" \
    -v "tenant_b_password_hash=${TENANT_B_PASS_HASH}" \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USERNAME}" \
    -d "${DB_NAME}" \
    -f - < "${SQL_FILE}"

echo "K3s E2E fixtures seeded for ${TENANT_B_USER}"
