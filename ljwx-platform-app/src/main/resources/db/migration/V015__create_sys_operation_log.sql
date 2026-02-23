-- =============================================================
-- V015: Create sys_operation_log — operation audit log
-- =============================================================

CREATE TABLE sys_operation_log (
    id              BIGINT        NOT NULL,
    title           VARCHAR(255)  NOT NULL DEFAULT '',
    business_type   SMALLINT      NOT NULL DEFAULT 0,
    method          VARCHAR(255)  NOT NULL DEFAULT '',
    request_method  VARCHAR(10)   NOT NULL DEFAULT '',
    request_url     VARCHAR(500)  NOT NULL DEFAULT '',
    request_param   TEXT,
    response_result TEXT,
    status          SMALLINT      NOT NULL DEFAULT 0,
    error_msg       VARCHAR(2000),
    operator_id     BIGINT        NOT NULL DEFAULT 0,
    operator_name   VARCHAR(100)  NOT NULL DEFAULT '',
    operator_ip     VARCHAR(50)   NOT NULL DEFAULT '',
    cost_time       BIGINT        NOT NULL DEFAULT 0,

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

CREATE INDEX idx_operation_log_tenant_time ON sys_operation_log (tenant_id, created_time DESC);
CREATE INDEX idx_operation_log_operator    ON sys_operation_log (operator_name);
CREATE INDEX idx_operation_log_status      ON sys_operation_log (status);

COMMENT ON TABLE  sys_operation_log                 IS '操作日志表';
COMMENT ON COLUMN sys_operation_log.id              IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_operation_log.title           IS '操作模块/描述';
COMMENT ON COLUMN sys_operation_log.business_type   IS '业务类型：0-其他,1-新增,2-修改,3-删除,4-查询,5-导出';
COMMENT ON COLUMN sys_operation_log.method          IS '请求方法全限定名';
COMMENT ON COLUMN sys_operation_log.request_method  IS 'HTTP请求方式';
COMMENT ON COLUMN sys_operation_log.request_url     IS '请求URL';
COMMENT ON COLUMN sys_operation_log.request_param   IS '请求参数（超4096字节截断，已脱敏）';
COMMENT ON COLUMN sys_operation_log.response_result IS '返回参数（超4096字节截断）';
COMMENT ON COLUMN sys_operation_log.status          IS '操作状态：0-正常,1-异常';
COMMENT ON COLUMN sys_operation_log.error_msg       IS '错误消息';
COMMENT ON COLUMN sys_operation_log.operator_id     IS '操作人员ID';
COMMENT ON COLUMN sys_operation_log.operator_name   IS '操作人员账号';
COMMENT ON COLUMN sys_operation_log.operator_ip     IS '操作人员IP';
COMMENT ON COLUMN sys_operation_log.cost_time       IS '操作耗时（毫秒）';
COMMENT ON COLUMN sys_operation_log.tenant_id       IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_operation_log.deleted         IS '软删除标志';
COMMENT ON COLUMN sys_operation_log.version         IS '乐观锁版本号';
