-- =============================================================
-- V013: Create sys_dict_data — dictionary item values
-- =============================================================

CREATE TABLE sys_dict_data (
    id          BIGINT        NOT NULL,
    dict_type   VARCHAR(100)  NOT NULL,
    dict_label  VARCHAR(100)  NOT NULL,
    dict_value  VARCHAR(100)  NOT NULL,
    sort_order  INT           NOT NULL DEFAULT 0,
    status      SMALLINT      NOT NULL DEFAULT 1,
    css_class   VARCHAR(100),
    list_class  VARCHAR(100),
    is_default  BOOLEAN       NOT NULL DEFAULT FALSE,
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

CREATE INDEX idx_dict_data_type ON sys_dict_data (tenant_id, dict_type) WHERE deleted = FALSE;

COMMENT ON TABLE  sys_dict_data               IS '字典数据表';
COMMENT ON COLUMN sys_dict_data.id            IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_dict_data.dict_type     IS '字典类型，外键关联 sys_dict_type.dict_type';
COMMENT ON COLUMN sys_dict_data.dict_label    IS '字典标签（显示名称）';
COMMENT ON COLUMN sys_dict_data.dict_value    IS '字典键值';
COMMENT ON COLUMN sys_dict_data.sort_order    IS '显示顺序';
COMMENT ON COLUMN sys_dict_data.status        IS '状态：1-正常，0-停用';
COMMENT ON COLUMN sys_dict_data.css_class     IS '样式属性（前端使用）';
COMMENT ON COLUMN sys_dict_data.list_class    IS '表格回显样式（前端使用）';
COMMENT ON COLUMN sys_dict_data.is_default    IS '是否默认值';
COMMENT ON COLUMN sys_dict_data.remark        IS '备注';
COMMENT ON COLUMN sys_dict_data.tenant_id     IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_dict_data.deleted       IS '软删除标志';
COMMENT ON COLUMN sys_dict_data.version       IS '乐观锁版本号';
