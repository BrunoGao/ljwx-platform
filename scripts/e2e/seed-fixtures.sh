#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SQL_FILE="${PROJECT_ROOT}/scripts/e2e/seed-fixtures.sql"

DB_NAME="${DB_NAME:-ljwx_platform}"
DB_USERNAME="${DB_USERNAME:-postgres}"
POSTGRES_IMAGE_FILTER="${POSTGRES_IMAGE_FILTER:-postgres:16-alpine}"
POSTGRES_CONTAINER_ID="${POSTGRES_CONTAINER_ID:-}"
TENANT_B_ID="${TENANT_B_ID:-200001}"
TENANT_B_ROLE_ID="${TENANT_B_ROLE_ID:-220001}"
TENANT_B_USER_ID="${TENANT_B_USER_ID:-220002}"
TENANT_B_USER="${TENANT_B_USER:-tenantB_admin}"
TENANT_B_PASS="${TENANT_B_PASS:-}"
TENANT_B_PASS_HASH="${TENANT_B_PASS_HASH:-}"

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

if [[ -z "${POSTGRES_CONTAINER_ID}" ]]; then
  POSTGRES_CONTAINER_ID="$(docker ps --filter "ancestor=${POSTGRES_IMAGE_FILTER}" --format '{{.ID}}' | head -n1)"
fi

if [[ -z "${POSTGRES_CONTAINER_ID}" ]]; then
  echo "未找到 PostgreSQL 容器，请确认 services.postgres 已启动" >&2
  exit 1
fi

docker exec -i "${POSTGRES_CONTAINER_ID}" \
  psql -v ON_ERROR_STOP=1 \
  -v "tenant_b_id=${TENANT_B_ID}" \
  -v "tenant_b_role_id=${TENANT_B_ROLE_ID}" \
  -v "tenant_b_user_id=${TENANT_B_USER_ID}" \
  -v "tenant_b_user=${TENANT_B_USER}" \
  -v "tenant_b_password_hash=${TENANT_B_PASS_HASH}" \
  -U "${DB_USERNAME}" \
  -d "${DB_NAME}" \
  -f - < "${SQL_FILE}"

echo "E2E fixtures seeded for ${TENANT_B_USER}"
