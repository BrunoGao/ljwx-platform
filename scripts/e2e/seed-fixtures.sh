#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-ljwx_platform}"
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-5432}"
DB_PASSWORD="${DB_PASSWORD:-}"
POSTGRES_IMAGE_FILTER="${POSTGRES_IMAGE_FILTER:-postgres:16-alpine}"
POSTGRES_CONTAINER_ID="${POSTGRES_CONTAINER_ID:-}"
PSQL_MODE="${PSQL_MODE:-auto}"
K8S_NAMESPACE="${K8S_NAMESPACE:-}"
K8S_PSQL_IMAGE="${K8S_PSQL_IMAGE:-postgres:16-alpine}"

TMP_SQL_FILE="$(mktemp)"
cleanup() {
  rm -f "${TMP_SQL_FILE}"
}
trap cleanup EXIT

cat >"${TMP_SQL_FILE}" <<'SQL'
-- Ensure tenant B exists with tenant_id=200001, and keep seeded entities aligned.
INSERT INTO sys_tenant (id, name, code, status, tenant_id, created_by, updated_by, version)
VALUES (200001, 'Tenant B', 'tenant_b', 1, 0, 0, 0, 1)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    id = EXCLUDED.id,
    code = EXCLUDED.code,
    status = EXCLUDED.status,
    deleted = FALSE,
    updated_time = CURRENT_TIMESTAMP;

-- Fix previously seeded records that used tenant_id=2.
UPDATE sys_permission SET tenant_id = 200001 WHERE id IN (220024, 220025, 220026, 220027, 220028);
UPDATE sys_role SET tenant_id = 200001 WHERE id = 220001;
UPDATE sys_user SET tenant_id = 200001 WHERE id = 220002;
UPDATE sys_role_permission SET tenant_id = 200001 WHERE role_id = 220001;
UPDATE sys_user_role SET tenant_id = 200001 WHERE user_id = 220002;

-- Ensure tenant-B menu permissions exist.
INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version) VALUES
  (220024, 200001, 'system:menu:list',   '菜单查询', 0, 0, 1),
  (220025, 200001, 'system:menu:detail', '菜单详情', 0, 0, 1),
  (220026, 200001, 'system:menu:create', '菜单新增', 0, 0, 1),
  (220027, 200001, 'system:menu:update', '菜单修改', 0, 0, 1),
  (220028, 200001, 'system:menu:delete', '菜单删除', 0, 0, 1)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Ensure tenant-B role exists.
INSERT INTO sys_role (id, tenant_id, name, code, status, created_by, updated_by, version)
VALUES (220001, 200001, 'Tenant B Menu Operator', 'TENANT_B_MENU_OPERATOR', 1, 0, 0, 1)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Ensure tenant-B admin test account exists.
-- Password hash corresponds to plain text: Admin@12345
INSERT INTO sys_user (id, tenant_id, username, password, nickname, status, created_by, updated_by, version)
VALUES (220002, 200001, 'tenantB_admin', '$2a$10$PnWlMR8Ox6UMTZj7Zm9uO.wSqzbjVt04UbeJ7q3RxDe8TSIP6efz2', 'Tenant B Admin', 1, 0, 0, 1)
ON CONFLICT (tenant_id, username) DO UPDATE
SET password = EXCLUDED.password,
    status = 1,
    deleted = FALSE,
    updated_time = CURRENT_TIMESTAMP;

-- Ensure tenant-B role has required menu permissions.
WITH role_row AS (
  SELECT id AS role_id
  FROM sys_role
  WHERE tenant_id = 200001 AND code = 'TENANT_B_MENU_OPERATOR'
),
perm_rows AS (
  SELECT id AS permission_id
  FROM sys_permission
  WHERE tenant_id = 200001
    AND code IN (
      'system:menu:list',
      'system:menu:detail',
      'system:menu:create',
      'system:menu:update',
      'system:menu:delete'
    )
  ORDER BY permission_id
),
pairs AS (
  SELECT role_row.role_id, perm_rows.permission_id, ROW_NUMBER() OVER () AS rn
  FROM role_row
  CROSS JOIN perm_rows
),
base AS (
  SELECT COALESCE(MAX(id), 320000) AS max_id FROM sys_role_permission
)
INSERT INTO sys_role_permission (id, tenant_id, role_id, permission_id, created_by, updated_by, version)
SELECT base.max_id + pairs.rn, 200001, pairs.role_id, pairs.permission_id, 0, 0, 1
FROM pairs
CROSS JOIN base
WHERE NOT EXISTS (
  SELECT 1
  FROM sys_role_permission rp
  WHERE rp.tenant_id = 200001
    AND rp.role_id = pairs.role_id
    AND rp.permission_id = pairs.permission_id
    AND rp.deleted = FALSE
);

-- Ensure tenant-B user-role mapping exists.
WITH role_row AS (
  SELECT id AS role_id
  FROM sys_role
  WHERE tenant_id = 200001 AND code = 'TENANT_B_MENU_OPERATOR'
),
user_row AS (
  SELECT id AS user_id
  FROM sys_user
  WHERE tenant_id = 200001 AND username = 'tenantB_admin'
),
base AS (
  SELECT COALESCE(MAX(id), 330000) AS max_id FROM sys_user_role
)
INSERT INTO sys_user_role (id, tenant_id, user_id, role_id, created_by, updated_by, version)
SELECT base.max_id + 1, 200001, user_row.user_id, role_row.role_id, 0, 0, 1
FROM role_row, user_row, base
WHERE NOT EXISTS (
  SELECT 1
  FROM sys_user_role ur
  WHERE ur.tenant_id = 200001
    AND ur.user_id = user_row.user_id
    AND ur.role_id = role_row.role_id
    AND ur.deleted = FALSE
);
SQL

run_via_docker() {
  local container_id="${POSTGRES_CONTAINER_ID}"
  if [[ -z "${container_id}" && -n "$(command -v docker || true)" ]]; then
    container_id="$(docker ps --filter "ancestor=${POSTGRES_IMAGE_FILTER}" --format '{{.ID}}' | head -n1)"
  fi

  if [[ -z "${container_id}" ]]; then
    echo "未找到 PostgreSQL 容器，请确认 compose/services.postgres 已启动" >&2
    return 1
  fi

  docker exec -i "${container_id}" psql -v ON_ERROR_STOP=1 -U "${DB_USERNAME}" -d "${DB_NAME}" <"${TMP_SQL_FILE}"
}

run_via_local_psql() {
  if ! command -v psql >/dev/null 2>&1; then
    echo "未安装 psql，无法使用本地 PostgreSQL 直连写入夹具" >&2
    return 1
  fi

  if [[ -z "${DB_PASSWORD}" ]]; then
    echo "DB_PASSWORD 为空，无法使用本地 PostgreSQL 直连写入夹具" >&2
    return 1
  fi

  PGPASSWORD="${DB_PASSWORD}" psql \
    -v ON_ERROR_STOP=1 \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USERNAME}" \
    -d "${DB_NAME}" \
    -f "${TMP_SQL_FILE}"
}

run_via_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "未安装 kubectl，无法通过 k3s/Kubernetes 临时 Pod 写入夹具" >&2
    return 1
  fi

  if [[ -z "${K8S_NAMESPACE}" ]]; then
    echo "K8S_NAMESPACE 未设置，无法通过 k3s/Kubernetes 临时 Pod 写入夹具" >&2
    return 1
  fi

  if [[ -z "${DB_PASSWORD}" ]]; then
    echo "DB_PASSWORD 为空，无法通过 k3s/Kubernetes 临时 Pod 写入夹具" >&2
    return 1
  fi

  local pod_name
  pod_name="ljwx-seed-fixtures-$(date +%s)"

  set +e
  kubectl -n "${K8S_NAMESPACE}" run "${pod_name}" \
    --image="${K8S_PSQL_IMAGE}" \
    --restart=Never \
    --rm -i --attach=true \
    --env="PGPASSWORD=${DB_PASSWORD}" \
    --command -- \
    psql \
      -v ON_ERROR_STOP=1 \
      -h "${DB_HOST}" \
      -p "${DB_PORT}" \
      -U "${DB_USERNAME}" \
      -d "${DB_NAME}" <"${TMP_SQL_FILE}"
  local rc=$?
  set -e

  kubectl -n "${K8S_NAMESPACE}" delete pod "${pod_name}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  return "${rc}"
}

case "${PSQL_MODE}" in
  auto)
    if run_via_docker; then
      :
    elif [[ -n "${K8S_NAMESPACE}" ]] && run_via_kubectl; then
      :
    elif run_via_local_psql; then
      :
    else
      echo "E2E fixture 写入失败：未找到可用 PostgreSQL 访问方式（docker / kubectl / psql）" >&2
      exit 1
    fi
    ;;
  docker)
    run_via_docker
    ;;
  psql)
    run_via_local_psql
    ;;
  kubectl)
    run_via_kubectl
    ;;
  *)
    echo "PSQL_MODE 非法: ${PSQL_MODE}，仅支持 auto/docker/psql/kubectl" >&2
    exit 1
    ;;
esac

echo "E2E fixtures seeded for tenantB_admin"
