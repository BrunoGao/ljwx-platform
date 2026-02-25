-- Test-only seed data for multi-tenant isolation assertions.

INSERT INTO sys_tenant (id, name, code, status, tenant_id, created_by, updated_by, version)
SELECT 2, 'Tenant B', 'tenant_b', 1, 0, 0, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM sys_tenant WHERE id = 2);

INSERT INTO sys_user (id, tenant_id, username, password, nickname, status, created_by, updated_by, version)
SELECT
    20001,
    2,
    'tenant_b_user',
    '$2a$10$PnWlMR8Ox6UMTZj7Zm9uO.wSqzbjVt04UbeJ7q3RxDe8TSIP6efz2',
    'Tenant B User',
    1,
    0,
    0,
    1
WHERE NOT EXISTS (SELECT 1 FROM sys_user WHERE id = 20001);
