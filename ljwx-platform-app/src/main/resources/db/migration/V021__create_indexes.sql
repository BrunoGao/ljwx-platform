-- =============================================================
-- V021: Create common indexes for frequently-queried columns
--
-- Tables already indexed in their own migrations:
--   sys_dict_type    — uq_dict_type_type (tenant_id, dict_type)
--   sys_dict_data    — idx_dict_data_type (tenant_id, dict_type)
--   sys_config       — uq_config_key (tenant_id, config_key)
--   sys_operation_log — idx_operation_log_tenant_time, operator, status
--   sys_login_log    — idx_login_log_tenant_time, username, status
--   sys_file         — idx_file_tenant_time, file_type
--   sys_notice       — idx_notice_tenant_time, status, notice_type
--
-- This migration adds indexes for the remaining business tables.
-- =============================================================

-- ─────────────────────────────────────────
-- sys_tenant
-- ─────────────────────────────────────────
CREATE INDEX idx_tenant_status       ON sys_tenant (status);
CREATE INDEX idx_tenant_created_time ON sys_tenant (created_time DESC);

-- ─────────────────────────────────────────
-- sys_user
-- Note: UNIQUE (tenant_id, username) already provides a
--       B-tree index whose leftmost column is tenant_id.
-- ─────────────────────────────────────────
CREATE INDEX idx_user_tenant_status  ON sys_user (tenant_id, status)       WHERE deleted = FALSE;
CREATE INDEX idx_user_tenant_time    ON sys_user (tenant_id, created_time DESC) WHERE deleted = FALSE;
CREATE INDEX idx_user_email          ON sys_user (tenant_id, email)         WHERE email IS NOT NULL AND deleted = FALSE;
CREATE INDEX idx_user_phone          ON sys_user (tenant_id, phone)         WHERE phone IS NOT NULL AND deleted = FALSE;

-- ─────────────────────────────────────────
-- sys_role
-- Note: UNIQUE (tenant_id, code) already provides index.
-- ─────────────────────────────────────────
CREATE INDEX idx_role_tenant_status  ON sys_role (tenant_id, status)           WHERE deleted = FALSE;
CREATE INDEX idx_role_tenant_time    ON sys_role (tenant_id, created_time DESC) WHERE deleted = FALSE;

-- ─────────────────────────────────────────
-- sys_user_role  (many-to-many join table)
-- ─────────────────────────────────────────
CREATE INDEX idx_user_role_user_id   ON sys_user_role (tenant_id, user_id)  WHERE deleted = FALSE;
CREATE INDEX idx_user_role_role_id   ON sys_user_role (tenant_id, role_id)  WHERE deleted = FALSE;

-- ─────────────────────────────────────────
-- sys_permission
-- Note: UNIQUE (tenant_id, code) already provides index.
-- ─────────────────────────────────────────
CREATE INDEX idx_permission_tenant_time ON sys_permission (tenant_id, created_time DESC) WHERE deleted = FALSE;

-- ─────────────────────────────────────────
-- sys_role_permission  (many-to-many join table)
-- ─────────────────────────────────────────
CREATE INDEX idx_role_perm_role_id   ON sys_role_permission (tenant_id, role_id)       WHERE deleted = FALSE;
CREATE INDEX idx_role_perm_perm_id   ON sys_role_permission (tenant_id, permission_id) WHERE deleted = FALSE;

-- ─────────────────────────────────────────
-- sys_job
-- ─────────────────────────────────────────
CREATE INDEX idx_job_tenant_status   ON sys_job (tenant_id, status)           WHERE deleted = FALSE;
CREATE INDEX idx_job_tenant_time     ON sys_job (tenant_id, created_time DESC) WHERE deleted = FALSE;
