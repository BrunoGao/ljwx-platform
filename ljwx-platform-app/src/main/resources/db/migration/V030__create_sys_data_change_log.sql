-- V030: 数据变更审计表
-- 记录业务数据的变更历史（UPDATE / DELETE 操作）

CREATE TABLE sys_data_change_log (
    id            BIGINT       NOT NULL,
    table_name    VARCHAR(64)  NOT NULL,
    record_id     BIGINT       NOT NULL,
    field_name    VARCHAR(64)  NOT NULL,
    old_value     TEXT         NOT NULL DEFAULT '',
    new_value     TEXT         NOT NULL DEFAULT '',
    operate_type  VARCHAR(16)  NOT NULL,
    -- 7 audit columns
    tenant_id     BIGINT       NOT NULL DEFAULT 0,
    created_by    BIGINT       NOT NULL DEFAULT 0,
    created_time  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by    BIGINT       NOT NULL DEFAULT 0,
    updated_time  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted       BOOLEAN      NOT NULL DEFAULT FALSE,
    version       INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

COMMENT ON TABLE  sys_data_change_log              IS '数据变更审计日志';
COMMENT ON COLUMN sys_data_change_log.id           IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_data_change_log.table_name   IS '表名';
COMMENT ON COLUMN sys_data_change_log.record_id    IS '记录ID';
COMMENT ON COLUMN sys_data_change_log.field_name   IS '字段名';
COMMENT ON COLUMN sys_data_change_log.old_value    IS '变更前值';
COMMENT ON COLUMN sys_data_change_log.new_value    IS '变更后值';
COMMENT ON COLUMN sys_data_change_log.operate_type IS '操作类型（UPDATE / DELETE）';

CREATE INDEX idx_data_change_log_table_record ON sys_data_change_log(table_name, record_id);
CREATE INDEX idx_data_change_log_created_time  ON sys_data_change_log(created_time);
