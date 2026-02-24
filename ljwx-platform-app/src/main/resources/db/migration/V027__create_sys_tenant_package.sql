-- =============================================================
-- V027: Create sys_tenant_package — tenant package management table
-- =============================================================

CREATE TABLE sys_tenant_package (
    id              BIGINT        NOT NULL,
    name            VARCHAR(64)   NOT NULL,
    menu_ids        TEXT          NOT NULL DEFAULT '',
    max_users       INT           NOT NULL DEFAULT 100,
    max_storage_mb  INT           NOT NULL DEFAULT 1024,
    status          SMALLINT      NOT NULL DEFAULT 1,

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

COMMENT ON TABLE  sys_tenant_package                  IS '租户套餐表';
COMMENT ON COLUMN sys_tenant_package.id               IS '套餐ID（Snowflake）';
COMMENT ON COLUMN sys_tenant_package.name             IS '套餐名称';
COMMENT ON COLUMN sys_tenant_package.menu_ids         IS '菜单ID列表（逗号分隔）';
COMMENT ON COLUMN sys_tenant_package.max_users        IS '最大用户数';
COMMENT ON COLUMN sys_tenant_package.max_storage_mb   IS '最大存储空间（MB）';
COMMENT ON COLUMN sys_tenant_package.status           IS '状态：1=正常，0=停用';
COMMENT ON COLUMN sys_tenant_package.tenant_id        IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_tenant_package.deleted          IS '软删除标志';
COMMENT ON COLUMN sys_tenant_package.version          IS '乐观锁版本号';

ALTER TABLE sys_tenant ADD COLUMN package_id BIGINT NOT NULL DEFAULT 0;

COMMENT ON COLUMN sys_tenant.package_id IS '关联套餐ID';
