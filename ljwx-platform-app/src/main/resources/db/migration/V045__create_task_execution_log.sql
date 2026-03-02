-- Phase 45: 任务执行日志表
CREATE TABLE sys_task_execution_log (
    id              BIGINT          NOT NULL,
    task_name       VARCHAR(100)    NOT NULL,
    task_group      VARCHAR(50)     NOT NULL,
    task_params     TEXT,
    status          VARCHAR(20)     NOT NULL,
    start_time      TIMESTAMP       NOT NULL,
    end_time        TIMESTAMP,
    duration        INT,
    result          TEXT,
    error_message   TEXT,
    error_stack     TEXT,
    server_ip       VARCHAR(50),
    server_name     VARCHAR(100),
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id, start_time)
) PARTITION BY RANGE (start_time);

-- 创建索引
CREATE INDEX idx_task_name_start_time ON sys_task_execution_log (task_name, start_time DESC);
CREATE INDEX idx_status_start_time ON sys_task_execution_log (status, start_time DESC);
CREATE INDEX idx_tenant_id ON sys_task_execution_log (tenant_id);
CREATE INDEX idx_start_time ON sys_task_execution_log (start_time DESC);

-- 创建分区（当前月及未来 3 个月）
CREATE TABLE sys_task_execution_log_2026_03 PARTITION OF sys_task_execution_log
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE sys_task_execution_log_2026_04 PARTITION OF sys_task_execution_log
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE sys_task_execution_log_2026_05 PARTITION OF sys_task_execution_log
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE sys_task_execution_log_2026_06 PARTITION OF sys_task_execution_log
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
