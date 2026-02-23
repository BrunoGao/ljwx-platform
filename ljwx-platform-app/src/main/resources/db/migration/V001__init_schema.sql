-- =============================================================
-- V001: Create sys_tenant — tenant registry
-- Flyway manages versioning; no idempotent DDL keywords needed.
-- =============================================================

CREATE TABLE sys_tenant (
    id           BIGINT        NOT NULL,
    name         VARCHAR(100)  NOT NULL,
    code         VARCHAR(50)   NOT NULL,
    status       SMALLINT      NOT NULL DEFAULT 1,
    remark       VARCHAR(500),

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id    BIGINT        NOT NULL DEFAULT 0,
    created_by   BIGINT        NOT NULL DEFAULT 0,
    created_time TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by   BIGINT        NOT NULL DEFAULT 0,
    updated_time TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted      BOOLEAN       NOT NULL DEFAULT FALSE,
    version      INT           NOT NULL DEFAULT 1,

    PRIMARY KEY (id),
    UNIQUE (code)
);

COMMENT ON TABLE  sys_tenant              IS '租户表';
COMMENT ON COLUMN sys_tenant.id           IS '租户ID（Snowflake）';
COMMENT ON COLUMN sys_tenant.name         IS '租户名称';
COMMENT ON COLUMN sys_tenant.code         IS '租户唯一编码';
COMMENT ON COLUMN sys_tenant.status       IS '状态：1-启用，0-禁用';
COMMENT ON COLUMN sys_tenant.tenant_id    IS '所属租户（自身为0，表示系统级）';
COMMENT ON COLUMN sys_tenant.deleted      IS '软删除标志';
COMMENT ON COLUMN sys_tenant.version      IS '乐观锁版本号';
