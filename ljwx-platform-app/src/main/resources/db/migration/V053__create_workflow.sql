-- Phase 53: Workflow Engine (Simplified)
-- 创建工作流引擎相关表

-- 流程定义表
CREATE TABLE wf_definition (
    id              BIGINT          NOT NULL,
    flow_key        VARCHAR(50)     NOT NULL,
    flow_name       VARCHAR(100)    NOT NULL,
    flow_version    INT             NOT NULL DEFAULT 1,
    flow_config     TEXT            NOT NULL,
    status          VARCHAR(20)     NOT NULL,

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_flow_key_version ON wf_definition(flow_key, flow_version);
CREATE INDEX idx_wf_definition_status ON wf_definition(status);
CREATE INDEX idx_wf_definition_tenant_id ON wf_definition(tenant_id);

COMMENT ON TABLE wf_definition IS '流程定义表';
COMMENT ON COLUMN wf_definition.flow_key IS '流程标识';
COMMENT ON COLUMN wf_definition.flow_name IS '流程名称';
COMMENT ON COLUMN wf_definition.flow_version IS '版本号';
COMMENT ON COLUMN wf_definition.flow_config IS 'JSON格式流程配置';
COMMENT ON COLUMN wf_definition.status IS '状态: DRAFT/PUBLISHED/ARCHIVED';

-- 流程实例表
CREATE TABLE wf_instance (
    id              BIGINT          NOT NULL,
    definition_id   BIGINT          NOT NULL,
    business_key    VARCHAR(100)    NOT NULL,
    business_type   VARCHAR(50)     NOT NULL,
    initiator_id    BIGINT          NOT NULL,
    current_node    VARCHAR(50),
    status          VARCHAR(20)     NOT NULL,
    start_time      TIMESTAMP       NOT NULL,
    end_time        TIMESTAMP,

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

CREATE INDEX idx_wf_instance_definition_id ON wf_instance(definition_id);
CREATE INDEX idx_wf_instance_business ON wf_instance(business_type, business_key);
CREATE INDEX idx_wf_instance_status ON wf_instance(status);
CREATE INDEX idx_wf_instance_tenant_id ON wf_instance(tenant_id);

COMMENT ON TABLE wf_instance IS '流程实例表';
COMMENT ON COLUMN wf_instance.definition_id IS '流程定义ID';
COMMENT ON COLUMN wf_instance.business_key IS '业务主键';
COMMENT ON COLUMN wf_instance.business_type IS '业务类型';
COMMENT ON COLUMN wf_instance.initiator_id IS '发起人ID';
COMMENT ON COLUMN wf_instance.current_node IS '当前节点';
COMMENT ON COLUMN wf_instance.status IS '状态: RUNNING/COMPLETED/REJECTED/CANCELLED';

-- 流程任务表
CREATE TABLE wf_task (
    id              BIGINT          NOT NULL,
    instance_id     BIGINT          NOT NULL,
    task_name       VARCHAR(100)    NOT NULL,
    task_type       VARCHAR(20)     NOT NULL,
    assignee_id     BIGINT          NOT NULL,
    status          VARCHAR(20)     NOT NULL,
    comment         TEXT,
    handle_time     TIMESTAMP,

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

CREATE INDEX idx_wf_task_instance_id ON wf_task(instance_id);
CREATE INDEX idx_wf_task_assignee_status ON wf_task(assignee_id, status);
CREATE INDEX idx_wf_task_tenant_id ON wf_task(tenant_id);

COMMENT ON TABLE wf_task IS '流程任务表';
COMMENT ON COLUMN wf_task.instance_id IS '流程实例ID';
COMMENT ON COLUMN wf_task.task_name IS '任务名称';
COMMENT ON COLUMN wf_task.task_type IS '任务类型: APPROVAL/NOTIFY';
COMMENT ON COLUMN wf_task.assignee_id IS '处理人ID';
COMMENT ON COLUMN wf_task.status IS '状态: PENDING/APPROVED/REJECTED';
COMMENT ON COLUMN wf_task.comment IS '审批意见';
COMMENT ON COLUMN wf_task.handle_time IS '处理时间';

-- 流程历史表
CREATE TABLE wf_history (
    id              BIGINT          NOT NULL,
    instance_id     BIGINT          NOT NULL,
    task_id         BIGINT,
    action          VARCHAR(20)     NOT NULL,
    operator_id     BIGINT          NOT NULL,
    comment         TEXT,

    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

CREATE INDEX idx_wf_history_instance_id ON wf_history(instance_id);
CREATE INDEX idx_wf_history_task_id ON wf_history(task_id);
CREATE INDEX idx_wf_history_tenant_id ON wf_history(tenant_id);

COMMENT ON TABLE wf_history IS '流程历史表';
COMMENT ON COLUMN wf_history.instance_id IS '流程实例ID';
COMMENT ON COLUMN wf_history.task_id IS '任务ID';
COMMENT ON COLUMN wf_history.action IS '操作: START/APPROVE/REJECT/CANCEL';
COMMENT ON COLUMN wf_history.operator_id IS '操作人ID';
COMMENT ON COLUMN wf_history.comment IS '操作意见';
