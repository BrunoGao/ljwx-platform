#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-ljwx_platform}"
POSTGRES_IMAGE_FILTER="${POSTGRES_IMAGE_FILTER:-postgres:16-alpine}"
POSTGRES_CONTAINER_ID="${POSTGRES_CONTAINER_ID:-}"

if [[ -z "${POSTGRES_CONTAINER_ID}" ]]; then
  POSTGRES_CONTAINER_ID="$(docker ps --filter "ancestor=${POSTGRES_IMAGE_FILTER}" --format '{{.ID}}' | head -n1)"
fi

if [[ -z "${POSTGRES_CONTAINER_ID}" ]]; then
  echo "未找到 PostgreSQL 容器，请确认 services.postgres 已启动" >&2
  exit 1
fi

docker exec -i "${POSTGRES_CONTAINER_ID}" psql -v ON_ERROR_STOP=1 -U postgres -d "${DB_NAME}" <<'SQL'
-- Ensure tenant B exists.
INSERT INTO sys_tenant (id, name, code, status, tenant_id, created_by, updated_by, version)
VALUES (200001, 'Tenant B', 'tenant_b', 1, 0, 0, 0, 1)
ON CONFLICT (code) DO NOTHING;

-- Ensure tenant-B menu permissions exist.
INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version) VALUES
  (220024, 2, 'system:menu:list',   '菜单查询', 0, 0, 1),
  (220025, 2, 'system:menu:detail', '菜单详情', 0, 0, 1),
  (220026, 2, 'system:menu:create', '菜单新增', 0, 0, 1),
  (220027, 2, 'system:menu:update', '菜单修改', 0, 0, 1),
  (220028, 2, 'system:menu:delete', '菜单删除', 0, 0, 1)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Ensure tenant-B role exists.
INSERT INTO sys_role (id, tenant_id, name, code, status, created_by, updated_by, version)
VALUES (220001, 2, 'Tenant B Menu Operator', 'TENANT_B_MENU_OPERATOR', 1, 0, 0, 1)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Ensure tenant-B admin test account exists.
-- Password hash corresponds to plain text: Admin@12345
INSERT INTO sys_user (id, tenant_id, username, password, nickname, status, created_by, updated_by, version)
VALUES (220002, 2, 'tenantB_admin', '$2a$10$PnWlMR8Ox6UMTZj7Zm9uO.wSqzbjVt04UbeJ7q3RxDe8TSIP6efz2', 'Tenant B Admin', 1, 0, 0, 1)
ON CONFLICT (tenant_id, username) DO UPDATE
SET password = EXCLUDED.password,
    status = 1,
    deleted = FALSE,
    updated_time = CURRENT_TIMESTAMP;

-- Ensure tenant-B role has required menu permissions.
WITH role_row AS (
  SELECT id AS role_id
  FROM sys_role
  WHERE tenant_id = 2 AND code = 'TENANT_B_MENU_OPERATOR'
),
perm_rows AS (
  SELECT id AS permission_id
  FROM sys_permission
  WHERE tenant_id = 2
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
SELECT base.max_id + pairs.rn, 2, pairs.role_id, pairs.permission_id, 0, 0, 1
FROM pairs
CROSS JOIN base
WHERE NOT EXISTS (
  SELECT 1
  FROM sys_role_permission rp
  WHERE rp.tenant_id = 2
    AND rp.role_id = pairs.role_id
    AND rp.permission_id = pairs.permission_id
    AND rp.deleted = FALSE
);

-- Ensure tenant-B user-role mapping exists.
WITH role_row AS (
  SELECT id AS role_id
  FROM sys_role
  WHERE tenant_id = 2 AND code = 'TENANT_B_MENU_OPERATOR'
),
user_row AS (
  SELECT id AS user_id
  FROM sys_user
  WHERE tenant_id = 2 AND username = 'tenantB_admin'
),
base AS (
  SELECT COALESCE(MAX(id), 330000) AS max_id FROM sys_user_role
)
INSERT INTO sys_user_role (id, tenant_id, user_id, role_id, created_by, updated_by, version)
SELECT base.max_id + 1, 2, user_row.user_id, role_row.role_id, 0, 0, 1
FROM role_row, user_row, base
WHERE NOT EXISTS (
  SELECT 1
  FROM sys_user_role ur
  WHERE ur.tenant_id = 2
    AND ur.user_id = user_row.user_id
    AND ur.role_id = role_row.role_id
    AND ur.deleted = FALSE
);
SQL

echo "E2E fixtures seeded for tenantB_admin"
