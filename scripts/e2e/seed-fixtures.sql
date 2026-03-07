-- Tenant-B E2E fixtures for both compose and k3s runtime.
-- Required psql variables:
--   tenant_b_id
--   tenant_b_role_id
--   tenant_b_user_id
--   tenant_b_user
--   tenant_b_password_hash

INSERT INTO sys_tenant (id, name, code, status, tenant_id, created_by, updated_by, version)
VALUES ((:'tenant_b_id')::bigint, 'Tenant B', 'tenant_b', 1, 0, 0, 0, 1)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    id = EXCLUDED.id,
    code = EXCLUDED.code,
    status = EXCLUDED.status,
    deleted = FALSE,
    updated_time = CURRENT_TIMESTAMP;

-- Fix previously seeded records that used inconsistent tenant IDs.
UPDATE sys_permission SET tenant_id = (:'tenant_b_id')::bigint WHERE id IN (220024, 220025, 220026, 220027, 220028);
UPDATE sys_role SET tenant_id = (:'tenant_b_id')::bigint WHERE id = (:'tenant_b_role_id')::bigint;
UPDATE sys_user SET tenant_id = (:'tenant_b_id')::bigint WHERE id = (:'tenant_b_user_id')::bigint;
UPDATE sys_role_permission SET tenant_id = (:'tenant_b_id')::bigint WHERE role_id = (:'tenant_b_role_id')::bigint;
UPDATE sys_user_role SET tenant_id = (:'tenant_b_id')::bigint WHERE user_id = (:'tenant_b_user_id')::bigint;

-- Ensure tenant-B menu permissions exist.
INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version) VALUES
  (220024, (:'tenant_b_id')::bigint, 'system:menu:list',   '菜单查询', 0, 0, 1),
  (220025, (:'tenant_b_id')::bigint, 'system:menu:detail', '菜单详情', 0, 0, 1),
  (220026, (:'tenant_b_id')::bigint, 'system:menu:create', '菜单新增', 0, 0, 1),
  (220027, (:'tenant_b_id')::bigint, 'system:menu:update', '菜单修改', 0, 0, 1),
  (220028, (:'tenant_b_id')::bigint, 'system:menu:delete', '菜单删除', 0, 0, 1)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Ensure tenant-B role exists.
INSERT INTO sys_role (id, tenant_id, name, code, status, created_by, updated_by, version)
VALUES ((:'tenant_b_role_id')::bigint, (:'tenant_b_id')::bigint, 'Tenant B Menu Operator', 'TENANT_B_MENU_OPERATOR', 1, 0, 0, 1)
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Keep a single canonical tenant-B test account by fixed ID.
DELETE FROM sys_user
WHERE tenant_id = (:'tenant_b_id')::bigint
  AND username = :'tenant_b_user'
  AND id <> (:'tenant_b_user_id')::bigint;

INSERT INTO sys_user (id, tenant_id, username, password, nickname, status, created_by, updated_by, version)
VALUES ((:'tenant_b_user_id')::bigint, (:'tenant_b_id')::bigint, :'tenant_b_user', :'tenant_b_password_hash', 'Tenant B Admin', 1, 0, 0, 1)
ON CONFLICT (id) DO UPDATE
SET tenant_id = EXCLUDED.tenant_id,
    username = EXCLUDED.username,
    password = EXCLUDED.password,
    status = 1,
    deleted = FALSE,
    updated_time = CURRENT_TIMESTAMP;

-- Ensure tenant-B role has required menu permissions.
WITH role_row AS (
  SELECT id AS role_id
  FROM sys_role
  WHERE tenant_id = (:'tenant_b_id')::bigint AND code = 'TENANT_B_MENU_OPERATOR'
),
perm_rows AS (
  SELECT id AS permission_id
  FROM sys_permission
  WHERE tenant_id = (:'tenant_b_id')::bigint
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
SELECT base.max_id + pairs.rn, (:'tenant_b_id')::bigint, pairs.role_id, pairs.permission_id, 0, 0, 1
FROM pairs
CROSS JOIN base
WHERE NOT EXISTS (
  SELECT 1
  FROM sys_role_permission rp
  WHERE rp.tenant_id = (:'tenant_b_id')::bigint
    AND rp.role_id = pairs.role_id
    AND rp.permission_id = pairs.permission_id
    AND rp.deleted = FALSE
);

-- Ensure tenant-B user-role mapping exists.
WITH role_row AS (
  SELECT id AS role_id
  FROM sys_role
  WHERE tenant_id = (:'tenant_b_id')::bigint AND code = 'TENANT_B_MENU_OPERATOR'
),
user_row AS (
  SELECT id AS user_id
  FROM sys_user
  WHERE id = (:'tenant_b_user_id')::bigint
),
base AS (
  SELECT COALESCE(MAX(id), 330000) AS max_id FROM sys_user_role
)
INSERT INTO sys_user_role (id, tenant_id, user_id, role_id, created_by, updated_by, version)
SELECT base.max_id + 1, (:'tenant_b_id')::bigint, user_row.user_id, role_row.role_id, 0, 0, 1
FROM role_row, user_row, base
WHERE NOT EXISTS (
  SELECT 1
  FROM sys_user_role ur
  WHERE ur.tenant_id = (:'tenant_b_id')::bigint
    AND ur.user_id = user_row.user_id
    AND ur.role_id = role_row.role_id
    AND ur.deleted = FALSE
);
