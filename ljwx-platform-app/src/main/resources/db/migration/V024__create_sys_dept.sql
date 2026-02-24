-- =============================================================
-- V024: Create sys_dept — department management table
-- =============================================================

CREATE TABLE sys_dept (
    id          BIGINT        NOT NULL,
    parent_id   BIGINT        NOT NULL DEFAULT 0,
    name        VARCHAR(64)   NOT NULL,
    sort        INT           NOT NULL DEFAULT 0,
    leader      VARCHAR(64)   NOT NULL DEFAULT '',
    phone       VARCHAR(20)   NOT NULL DEFAULT '',
    email       VARCHAR(100)  NOT NULL DEFAULT '',
    status      SMALLINT      NOT NULL DEFAULT 1,

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

COMMENT ON TABLE  sys_dept              IS '部门表';
COMMENT ON COLUMN sys_dept.id          IS '部门ID（Snowflake）';
COMMENT ON COLUMN sys_dept.parent_id   IS '父部门ID，0=根节点';
COMMENT ON COLUMN sys_dept.name        IS '部门名称';
COMMENT ON COLUMN sys_dept.sort        IS '显示排序';
COMMENT ON COLUMN sys_dept.leader      IS '负责人';
COMMENT ON COLUMN sys_dept.phone       IS '联系电话';
COMMENT ON COLUMN sys_dept.email       IS '邮箱';
COMMENT ON COLUMN sys_dept.status      IS '状态：1=正常，0=停用';
COMMENT ON COLUMN sys_dept.tenant_id   IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_dept.deleted     IS '软删除标志';
COMMENT ON COLUMN sys_dept.version     IS '乐观锁版本号';
