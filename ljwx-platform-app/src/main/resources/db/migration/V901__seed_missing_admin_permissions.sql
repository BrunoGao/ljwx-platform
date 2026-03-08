-- =============================================================
-- V901: Seed controller permissions missing from local baseline and
--       grant them to admin role (id=1).
-- NOTE: local Flyway schema version is already 900, so new seed
--       migrations must use a version higher than 900.
-- =============================================================

WITH missing_permissions(code, name) AS (
    VALUES
        ('form:data:add', 'form:data:add'),
        ('form:data:edit', 'form:data:edit'),
        ('form:data:list', 'form:data:list'),
        ('form:data:query', 'form:data:query'),
        ('form:def:add', 'form:def:add'),
        ('form:def:delete', 'form:def:delete'),
        ('form:def:edit', 'form:def:edit'),
        ('form:def:list', 'form:def:list'),
        ('form:def:query', 'form:def:query'),
        ('log:write', 'log:write'),
        ('report:def:add', 'report:def:add'),
        ('report:def:delete', 'report:def:delete'),
        ('report:def:edit', 'report:def:edit'),
        ('report:def:execute', 'report:def:execute'),
        ('report:def:list', 'report:def:list'),
        ('report:def:query', 'report:def:query'),
        ('system:ai:chat', 'system:ai:chat'),
        ('system:ai:config:edit', 'system:ai:config:edit'),
        ('system:ai:config:query', 'system:ai:config:query'),
        ('system:ai:log:list', 'system:ai:log:list'),
        ('system:audit:list', 'system:audit:list'),
        ('system:customfield:add', 'system:customfield:add'),
        ('system:customfield:delete', 'system:customfield:delete'),
        ('system:customfield:edit', 'system:customfield:edit'),
        ('system:customfield:list', 'system:customfield:list'),
        ('system:importExport:export', 'system:importExport:export'),
        ('system:importExport:import', 'system:importExport:import'),
        ('system:importExport:list', 'system:importExport:list'),
        ('system:importExport:query', 'system:importExport:query'),
        ('system:message:inbox:delete', 'system:message:inbox:delete'),
        ('system:message:inbox:list', 'system:message:inbox:list'),
        ('system:message:inbox:read', 'system:message:inbox:read'),
        ('system:message:record:list', 'system:message:record:list'),
        ('system:message:record:query', 'system:message:record:query'),
        ('system:message:send', 'system:message:send'),
        ('system:message:subscription:add', 'system:message:subscription:add'),
        ('system:message:subscription:delete', 'system:message:subscription:delete'),
        ('system:message:subscription:edit', 'system:message:subscription:edit'),
        ('system:message:subscription:list', 'system:message:subscription:list'),
        ('system:message:subscription:query', 'system:message:subscription:query'),
        ('system:message:template:add', 'system:message:template:add'),
        ('system:message:template:delete', 'system:message:template:delete'),
        ('system:message:template:edit', 'system:message:template:edit'),
        ('system:message:template:list', 'system:message:template:list'),
        ('system:message:template:query', 'system:message:template:query'),
        ('system:openApi:app:add', 'system:openApi:app:add'),
        ('system:openApi:app:delete', 'system:openApi:app:delete'),
        ('system:openApi:app:edit', 'system:openApi:app:edit'),
        ('system:openApi:app:list', 'system:openApi:app:list'),
        ('system:openApi:app:query', 'system:openApi:app:query'),
        ('system:openApi:secret:add', 'system:openApi:secret:add'),
        ('system:openApi:secret:delete', 'system:openApi:secret:delete'),
        ('system:openApi:secret:edit', 'system:openApi:secret:edit'),
        ('system:openApi:secret:list', 'system:openApi:secret:list'),
        ('system:post:add', 'system:post:add'),
        ('system:post:delete', 'system:post:delete'),
        ('system:post:edit', 'system:post:edit'),
        ('system:post:list', 'system:post:list'),
        ('system:post:query', 'system:post:query'),
        ('system:role:edit', 'system:role:edit'),
        ('system:role:query', 'system:role:query'),
        ('system:taskLog:clean', 'system:taskLog:clean'),
        ('system:taskLog:delete', 'system:taskLog:delete'),
        ('system:taskLog:list', 'system:taskLog:list'),
        ('system:taskLog:query', 'system:taskLog:query'),
        ('system:taskLog:stats', 'system:taskLog:stats'),
        ('system:tenant:cancel', 'system:tenant:cancel'),
        ('system:tenant:create', 'system:tenant:create'),
        ('system:tenant:delete', 'system:tenant:delete'),
        ('system:tenant:detail', 'system:tenant:detail'),
        ('system:tenant:freeze', 'system:tenant:freeze'),
        ('system:tenant:init', 'system:tenant:init'),
        ('system:tenant:list', 'system:tenant:list'),
        ('system:tenant:unfreeze', 'system:tenant:unfreeze'),
        ('system:tenant:update', 'system:tenant:update'),
        ('system:webhook:add', 'system:webhook:add'),
        ('system:webhook:delete', 'system:webhook:delete'),
        ('system:webhook:edit', 'system:webhook:edit'),
        ('system:webhook:list', 'system:webhook:list'),
        ('system:webhook:log:list', 'system:webhook:log:list'),
        ('system:webhook:query', 'system:webhook:query'),
        ('system:workflow:definition:add', 'system:workflow:definition:add'),
        ('system:workflow:definition:delete', 'system:workflow:definition:delete'),
        ('system:workflow:definition:edit', 'system:workflow:definition:edit'),
        ('system:workflow:definition:list', 'system:workflow:definition:list'),
        ('system:workflow:instance:add', 'system:workflow:instance:add'),
        ('system:workflow:instance:query', 'system:workflow:instance:query'),
        ('system:workflow:task:approve', 'system:workflow:task:approve'),
        ('system:workflow:task:list', 'system:workflow:task:list'),
        ('system:workflow:task:reject', 'system:workflow:task:reject'),
        ('tenant:brand:edit', 'tenant:brand:edit'),
        ('tenant:brand:list', 'tenant:brand:list'),
        ('tenant:domain:add', 'tenant:domain:add'),
        ('tenant:domain:delete', 'tenant:domain:delete'),
        ('tenant:domain:list', 'tenant:domain:list'),
        ('tenant:domain:query', 'tenant:domain:query'),
        ('tenant:domain:setPrimary', 'tenant:domain:setPrimary'),
        ('tenant:domain:verify', 'tenant:domain:verify')
),
insert_permissions AS (
    INSERT INTO sys_permission (id, tenant_id, code, name, created_by, updated_by, version)
    SELECT
        (SELECT COALESCE(MAX(id), 0) FROM sys_permission)
            + ROW_NUMBER() OVER (ORDER BY code),
        1,
        code,
        name,
        0,
        0,
        1
    FROM missing_permissions mp
    WHERE NOT EXISTS (
        SELECT 1
        FROM sys_permission p
        WHERE p.tenant_id = 1
          AND p.code = mp.code
    )
    RETURNING id, code
),
grant_permissions AS (
    SELECT p.id AS permission_id
    FROM sys_permission p
    JOIN missing_permissions mp
      ON mp.code = p.code
    WHERE p.tenant_id = 1
      AND NOT EXISTS (
          SELECT 1
          FROM sys_role_permission rp
          WHERE rp.tenant_id = 1
            AND rp.role_id = 1
            AND rp.permission_id = p.id
            AND rp.deleted = FALSE
      )
)
INSERT INTO sys_role_permission (id, tenant_id, role_id, permission_id, created_by, updated_by, version)
SELECT
    (SELECT COALESCE(MAX(id), 0) FROM sys_role_permission)
        + ROW_NUMBER() OVER (ORDER BY permission_id),
    1,
    1,
    permission_id,
    0,
    0,
    1
FROM grant_permissions;
