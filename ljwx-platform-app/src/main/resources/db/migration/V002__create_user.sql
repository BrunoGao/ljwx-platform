-- =============================================================
-- V002: Create sys_user — user accounts per tenant
-- =============================================================

CREATE TABLE sys_user (
    id            BIGINT        NOT NULL,
    username      VARCHAR(50)   NOT NULL,
    password      VARCHAR(255)  NOT NULL,
    nickname      VARCHAR(100),
    email         VARCHAR(100),
    phone         VARCHAR(20),
    avatar        VARCHAR(500),
    status        SMALLINT      NOT NULL DEFAULT 1,

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id     BIGINT        NOT NULL DEFAULT 0,
    created_by    BIGINT        NOT NULL DEFAULT 0,
    created_time  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by    BIGINT        NOT NULL DEFAULT 0,
    updated_time  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted       BOOLEAN       NOT NULL DEFAULT FALSE,
    version       INT           NOT NULL DEFAULT 1,

    PRIMARY KEY (id),
    UNIQUE (tenant_id, username)
);

COMMENT ON TABLE  sys_user             IS '用户表';
COMMENT ON COLUMN sys_user.id          IS '用户ID（Snowflake）';
COMMENT ON COLUMN sys_user.username    IS '登录用户名（租户内唯一）';
COMMENT ON COLUMN sys_user.password    IS 'BCrypt(cost=10) 密码哈希';
COMMENT ON COLUMN sys_user.status      IS '状态：1-启用，0-禁用';
COMMENT ON COLUMN sys_user.deleted     IS '软删除标志';
COMMENT ON COLUMN sys_user.version     IS '乐观锁版本号';
