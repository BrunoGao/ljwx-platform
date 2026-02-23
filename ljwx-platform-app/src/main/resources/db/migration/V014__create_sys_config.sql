-- =============================================================
-- V014: Create sys_config — system configuration parameters
-- =============================================================

CREATE TABLE sys_config (
    id            BIGINT        NOT NULL,
    config_name   VARCHAR(100)  NOT NULL,
    config_key    VARCHAR(100)  NOT NULL,
    config_value  VARCHAR(500)  NOT NULL,
    config_type   SMALLINT      NOT NULL DEFAULT 1,
    remark        VARCHAR(500),

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

CREATE UNIQUE INDEX uq_config_key ON sys_config (tenant_id, config_key) WHERE deleted = FALSE;

COMMENT ON TABLE  sys_config                  IS '系统配置表';
COMMENT ON COLUMN sys_config.id               IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_config.config_name      IS '参数名称';
COMMENT ON COLUMN sys_config.config_key       IS '参数键名（唯一标识）';
COMMENT ON COLUMN sys_config.config_value     IS '参数键值';
COMMENT ON COLUMN sys_config.config_type      IS '系统内置：1-是，0-否';
COMMENT ON COLUMN sys_config.remark           IS '备注';
COMMENT ON COLUMN sys_config.tenant_id        IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_config.deleted          IS '软删除标志';
COMMENT ON COLUMN sys_config.version          IS '乐观锁版本号';
