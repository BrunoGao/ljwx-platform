-- Phase 53: Workflow Engine (Simplified)
-- 创建工作流引擎相关表

-- 流程定义表
CREATE TABLE wf_definition (
    id              BIGINT          NOT NULL,
    flow_key        VARCHAR(100)    NOT NULL,
    flow_name       VARCHAR(200)    NOT NULL,
    flow_version    INT             NOT NULL DEFAULT 1,
    flow_config     TEXT            NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'DRAFT',

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 0,

    PRIMARY KEY (id)
);

CREATE INDEX idx_wf_definition_flow_key ON wf_definition(flow_key);
CREATE INDEX idx_wf_definition_status ON wf_definition(status);

-- 流程实例表
CREATE TABLE wf_instance (
    id              BIGINT          NOT NULL,
    definition_id   BIGINT          NOT NULL,
    business_key    VARCHAR(100),
    business_type   VARCHAR(50),
    initiator_id    BIGINT          NOT NULL,
    current_node    VARCHAR(100),
    status          VARCHAR(20)     NOT NULL DEFAULT 'RUNNING',
    start_time      TIMESTAMP       NOT NULL,
    end_time        TIMESTAMP,

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 0,

    PRIMARY KEY (id)
);

CREATE INDEX idx_wf_instance_definition_id ON wf_instance(definition_id);
CREATE INDEX idx_wf_instance_business_key ON wf_instance(business_key);
CREATE INDEX idx_wf_instance_status ON wf_instance(status);

-- 流程任务表
CREATE TABLE wf_task (
    id              BIGINT          NOT NULL,
    instance_id     BIGINT          NOT NULL,
    task_name       VARCHAR(200)    NOT NULL,
    task_type       VARCHAR(50)     NOT NULL,
    assignee_id     BIGINT          NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'PENDING',
    comment         TEXT,
    handle_time     TIMESTAMP,

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 0,

    PRIMARY KEY (id)
);

CREATE INDEX idx_wf_task_instance_id ON wf_task(instance_id);
CREATE INDEX idx_wf_task_assignee_id ON wf_task(assignee_id);
CREATE INDEX idx_wf_task_status ON wf_task(status);

-- 流程历史表
CREATE TABLE wf_history (
    id              BIGINT          NOT NULL,
    instance_id     BIGINT          NOT NULL,
    task_id         BIGINT,
    action          VARCHAR(50)     NOT NULL,
    operator_id     BIGINT          NOT NULL,
    comment         TEXT,

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 0,

    PRIMARY KEY (id)
);

CREATE INDEX idx_wf_history_instance_id ON wf_history(instance_id);
CREATE INDEX idx_wf_history_task_id ON wf_history(task_id);
