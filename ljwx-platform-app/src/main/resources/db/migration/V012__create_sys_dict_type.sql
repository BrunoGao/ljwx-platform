-- =============================================================
-- V012: Create sys_dict_type — dictionary type definitions
-- =============================================================

CREATE TABLE sys_dict_type (
    id          BIGINT        NOT NULL,
    dict_name   VARCHAR(100)  NOT NULL,
    dict_type   VARCHAR(100)  NOT NULL,
    status      SMALLINT      NOT NULL DEFAULT 1,
    remark      VARCHAR(500),

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

CREATE UNIQUE INDEX uq_dict_type_type ON sys_dict_type (tenant_id, dict_type) WHERE deleted = FALSE;

COMMENT ON TABLE  sys_dict_type              IS '字典类型表';
COMMENT ON COLUMN sys_dict_type.id           IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_dict_type.dict_name    IS '字典名称';
COMMENT ON COLUMN sys_dict_type.dict_type    IS '字典类型（唯一标识，如 sys_user_sex）';
COMMENT ON COLUMN sys_dict_type.status       IS '状态：1-正常，0-停用';
COMMENT ON COLUMN sys_dict_type.remark       IS '备注';
COMMENT ON COLUMN sys_dict_type.tenant_id    IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_dict_type.deleted      IS '软删除标志';
COMMENT ON COLUMN sys_dict_type.version      IS '乐观锁版本号';
