-- Phase 49: Webhook Event Push
-- Create sys_webhook_config and sys_webhook_log tables

-- Webhook Configuration Table
CREATE TABLE sys_webhook_config (
    id                BIGINT       NOT NULL,
    webhook_name      VARCHAR(100) NOT NULL,
    webhook_url       VARCHAR(500) NOT NULL,
    event_types       TEXT         NOT NULL,
    secret_key        VARCHAR(128) NOT NULL,
    status            VARCHAR(20)  NOT NULL,
    retry_count       INT          NOT NULL DEFAULT 5,
    timeout_seconds   INT          NOT NULL DEFAULT 5,
    tenant_id         BIGINT       NOT NULL DEFAULT 0,
    created_by        BIGINT       NOT NULL DEFAULT 0,
    created_time      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by        BIGINT       NOT NULL DEFAULT 0,
    updated_time      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted           BOOLEAN      NOT NULL DEFAULT FALSE,
    version           INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Webhook Log Table
CREATE TABLE sys_webhook_log (
    id                BIGINT       NOT NULL,
    webhook_id        BIGINT       NOT NULL,
    event_type        VARCHAR(50)  NOT NULL,
    event_data        TEXT         NOT NULL,
    request_url       VARCHAR(500) NOT NULL,
    request_headers   TEXT,
    request_body      TEXT         NOT NULL,
    response_status   INT,
    response_body     TEXT,
    retry_times       INT          NOT NULL DEFAULT 0,
    status            VARCHAR(20)  NOT NULL,
    error_message     TEXT,
    tenant_id         BIGINT       NOT NULL DEFAULT 0,
    created_by        BIGINT       NOT NULL DEFAULT 0,
    created_time      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by        BIGINT       NOT NULL DEFAULT 0,
    updated_time      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted           BOOLEAN      NOT NULL DEFAULT FALSE,
    version           INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Indexes for sys_webhook_config
CREATE INDEX idx_webhook_config_status ON sys_webhook_config(status);
CREATE INDEX idx_webhook_config_tenant_id ON sys_webhook_config(tenant_id);

-- Indexes for sys_webhook_log
CREATE INDEX idx_webhook_log_webhook_id ON sys_webhook_log(webhook_id);
CREATE INDEX idx_webhook_log_status ON sys_webhook_log(status);
CREATE INDEX idx_webhook_log_tenant_id ON sys_webhook_log(tenant_id);
CREATE INDEX idx_webhook_log_created_time ON sys_webhook_log(created_time);
