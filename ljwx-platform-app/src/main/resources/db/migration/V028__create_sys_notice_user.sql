-- =============================================================
-- V028: Create sys_notice_user — notice read-status tracking table
-- =============================================================

CREATE TABLE sys_notice_user (
    id         BIGINT        NOT NULL,
    notice_id  BIGINT        NOT NULL,
    user_id    BIGINT        NOT NULL,
    read_time  TIMESTAMPTZ   NULL,

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id    BIGINT     NOT NULL DEFAULT 0,
    created_by   BIGINT     NOT NULL DEFAULT 0,
    created_time TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by   BIGINT     NOT NULL DEFAULT 0,
    updated_time TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted      BOOLEAN    NOT NULL DEFAULT FALSE,
    version      INT        NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

CREATE INDEX idx_notice_user ON sys_notice_user (notice_id, user_id);

COMMENT ON TABLE  sys_notice_user              IS '通知用户关联表（记录已读状态）';
COMMENT ON COLUMN sys_notice_user.id           IS '记录ID（Snowflake）';
COMMENT ON COLUMN sys_notice_user.notice_id    IS '通知ID';
COMMENT ON COLUMN sys_notice_user.user_id      IS '用户ID';
COMMENT ON COLUMN sys_notice_user.read_time    IS '阅读时间，NULL 表示未读';
COMMENT ON COLUMN sys_notice_user.tenant_id    IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_notice_user.deleted      IS '软删除标志';
COMMENT ON COLUMN sys_notice_user.version      IS '乐观锁版本号';
