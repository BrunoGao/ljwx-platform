-- =============================================================
-- V005: Seed default tenant (id=1, tenant_id=0 = system level)
-- =============================================================

INSERT INTO sys_tenant (id, name, code, status, tenant_id, created_by, updated_by, version)
VALUES (1, '默认租户', 'default', 1, 0, 0, 0, 1);
