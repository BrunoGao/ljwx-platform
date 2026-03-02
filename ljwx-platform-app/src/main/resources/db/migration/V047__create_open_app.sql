-- Phase 47: Open API Application Management
-- Create sys_open_app table

CREATE TABLE sys_open_app (
    id              BIGINT          NOT NULL,
    app_key         VARCHAR(64)     NOT NULL,
    app_secret      VARCHAR(128)    NOT NULL,
    app_name        VARCHAR(100)    NOT NULL,
    app_type        VARCHAR(20)     NOT NULL,
    status          VARCHAR(20)     NOT NULL,
    rate_limit      INT             NOT NULL DEFAULT 100,
    ip_whitelist    TEXT,
    expire_time     TIMESTAMP,
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Create unique index on app_key
CREATE UNIQUE INDEX uk_app_key ON sys_open_app(app_key);

-- Create index on status for filtering
CREATE INDEX idx_status ON sys_open_app(status);

-- Create index on tenant_id for multi-tenancy
CREATE INDEX idx_open_app_tenant_id ON sys_open_app(tenant_id);

COMMENT ON TABLE sys_open_app IS 'Open API Application Management';
COMMENT ON COLUMN sys_open_app.id IS 'Primary Key (Snowflake ID)';
COMMENT ON COLUMN sys_open_app.app_key IS 'Application Key (UUID format)';
COMMENT ON COLUMN sys_open_app.app_secret IS 'Application Secret (HMAC signature)';
COMMENT ON COLUMN sys_open_app.app_name IS 'Application Name';
COMMENT ON COLUMN sys_open_app.app_type IS 'Application Type: INTERNAL / EXTERNAL';
COMMENT ON COLUMN sys_open_app.status IS 'Status: ENABLED / DISABLED';
COMMENT ON COLUMN sys_open_app.rate_limit IS 'Rate Limit (requests per second)';
COMMENT ON COLUMN sys_open_app.ip_whitelist IS 'IP Whitelist (JSON array)';
COMMENT ON COLUMN sys_open_app.expire_time IS 'Expiration Time';
