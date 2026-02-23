-- =============================================================
-- V009: Assign admin role (id=1) to admin user (id=1)
-- =============================================================

INSERT INTO sys_user_role (id, tenant_id, user_id, role_id, created_by, updated_by, version)
VALUES (1, 1, 1, 1, 0, 0, 1);
