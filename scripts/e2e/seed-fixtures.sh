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
TENANT_B_PASS="${TENANT_B_PASS:-Admin@12345}"
TENANT_B_PASS_HASH="${TENANT_B_PASS_HASH:-}"
DEFAULT_TENANT_B_PASS_HASH='$2a$10$PnWlMR8Ox6UMTZj7Zm9uO.wSqzbjVt04UbeJ7q3RxDe8TSIP6efz2'

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "未找到 SQL 文件: ${SQL_FILE}" >&2
  exit 1
fi

if [[ -z "${TENANT_B_PASS_HASH}" ]]; then
  if [[ "${TENANT_B_PASS}" == "Admin@12345" ]]; then
    TENANT_B_PASS_HASH="${DEFAULT_TENANT_B_PASS_HASH}"
  else
    echo "TENANT_B_PASS 不是默认值，且未提供 TENANT_B_PASS_HASH，无法执行夹具修复" >&2
    exit 1
  fi
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
