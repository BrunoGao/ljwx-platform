-- =============================================================
-- V016: Create sys_login_log — login audit log
-- =============================================================

CREATE TABLE sys_login_log (
    id           BIGINT        NOT NULL,
    username     VARCHAR(100)  NOT NULL DEFAULT '',
    ip           VARCHAR(50)   NOT NULL DEFAULT '',
    location     VARCHAR(255)  NOT NULL DEFAULT '',
    browser      VARCHAR(100)  NOT NULL DEFAULT '',
    os           VARCHAR(100)  NOT NULL DEFAULT '',
    status       SMALLINT      NOT NULL DEFAULT 0,
    msg          VARCHAR(500)  NOT NULL DEFAULT '',

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

CREATE INDEX idx_login_log_tenant_time ON sys_login_log (tenant_id, created_time DESC);
CREATE INDEX idx_login_log_username    ON sys_login_log (username);
CREATE INDEX idx_login_log_status      ON sys_login_log (status);

COMMENT ON TABLE  sys_login_log              IS '登录日志表';
COMMENT ON COLUMN sys_login_log.id           IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_login_log.username     IS '登录账号';
COMMENT ON COLUMN sys_login_log.ip           IS '登录IP';
COMMENT ON COLUMN sys_login_log.location     IS '登录地点';
COMMENT ON COLUMN sys_login_log.browser      IS '浏览器类型';
COMMENT ON COLUMN sys_login_log.os           IS '操作系统';
COMMENT ON COLUMN sys_login_log.status       IS '登录状态：0-成功,1-失败';
COMMENT ON COLUMN sys_login_log.msg          IS '提示消息';
COMMENT ON COLUMN sys_login_log.tenant_id    IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_login_log.deleted      IS '软删除标志';
COMMENT ON COLUMN sys_login_log.version      IS '乐观锁版本号';
