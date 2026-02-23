-- =============================================================
-- V011: Create sys_job — per-tenant scheduled job definitions
-- =============================================================

CREATE TABLE sys_job (
    id              BIGINT        NOT NULL,
    job_name        VARCHAR(200)  NOT NULL,
    job_group       VARCHAR(200)  NOT NULL DEFAULT 'DEFAULT',
    job_class_name  VARCHAR(500)  NOT NULL,
    cron_expression VARCHAR(120)  NOT NULL,
    description     VARCHAR(500),
    status          SMALLINT      NOT NULL DEFAULT 1,

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id     BIGINT     NOT NULL DEFAULT 0,
    created_by    BIGINT     NOT NULL DEFAULT 0,
    created_time  TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by    BIGINT     NOT NULL DEFAULT 0,
    updated_time  TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted       BOOLEAN    NOT NULL DEFAULT FALSE,
    version       INT        NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

COMMENT ON TABLE  sys_job                 IS '定时任务表';
COMMENT ON COLUMN sys_job.id              IS '任务ID（Snowflake）';
COMMENT ON COLUMN sys_job.job_name        IS '任务名称';
COMMENT ON COLUMN sys_job.job_group       IS '任务分组';
COMMENT ON COLUMN sys_job.job_class_name  IS '任务执行类全路径';
COMMENT ON COLUMN sys_job.cron_expression IS 'Cron 表达式';
COMMENT ON COLUMN sys_job.description     IS '任务描述';
COMMENT ON COLUMN sys_job.status          IS '状态：1-正常，0-暂停';
COMMENT ON COLUMN sys_job.tenant_id       IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_job.deleted         IS '软删除标志';
COMMENT ON COLUMN sys_job.version         IS '乐观锁版本号';
