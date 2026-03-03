-- Phase 34: Outbox 事件表 (Outbox Event Pattern)
-- 用于保证"写库+发消息"的原子性,实现事件最终一致性

-- Drop table if exists to handle out-of-order migration scenarios
DROP TABLE IF EXISTS sys_outbox_event CASCADE;

CREATE TABLE sys_outbox_event (
    id                  BIGINT          NOT NULL,
    aggregate_type      VARCHAR(100)    NOT NULL,
    aggregate_id        BIGINT          NOT NULL,
    event_type          VARCHAR(100)    NOT NULL,
    payload             JSONB           NOT NULL,
    status              VARCHAR(20)     NOT NULL,
    retry_count         INT             NOT NULL DEFAULT 0,
    max_retry           INT             NOT NULL DEFAULT 3,
    next_retry_time     TIMESTAMP,
    sent_time           TIMESTAMP,
    error_message       TEXT,
    tenant_id           BIGINT          NOT NULL DEFAULT 0,
    created_by          BIGINT          NOT NULL DEFAULT 0,
    created_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL DEFAULT 0,
    updated_time        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted             BOOLEAN         NOT NULL DEFAULT FALSE,
    version             INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- 创建索引
CREATE INDEX idx_outbox_status_retry ON sys_outbox_event (status, next_retry_time) WHERE status = 'PENDING';
CREATE INDEX idx_outbox_aggregate ON sys_outbox_event (aggregate_type, aggregate_id);
CREATE INDEX idx_outbox_tenant_id ON sys_outbox_event (tenant_id);
CREATE INDEX idx_outbox_created_time ON sys_outbox_event (created_time);

-- PostgreSQL NOTIFY 触发器函数
CREATE OR REPLACE FUNCTION notify_outbox_event()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('outbox_event_channel', NEW.id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER outbox_event_notify
AFTER INSERT ON sys_outbox_event
FOR EACH ROW
EXECUTE FUNCTION notify_outbox_event();
