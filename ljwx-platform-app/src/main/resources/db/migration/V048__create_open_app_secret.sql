-- Phase 48: Open API Secret Management
-- Create open_app_secret table

CREATE TABLE open_app_secret (
    id              BIGINT          NOT NULL,
    app_id          BIGINT          NOT NULL,
    secret_key      VARCHAR(128)    NOT NULL,
    secret_version  INT             NOT NULL DEFAULT 1,
    status          VARCHAR(20)     NOT NULL,
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

CREATE INDEX idx_app_id ON open_app_secret(app_id);
CREATE INDEX idx_open_app_secret_status ON open_app_secret(status);
CREATE INDEX idx_open_app_secret_tenant_id ON open_app_secret(tenant_id);

DO $$
BEGIN
    IF to_regclass('public.sys_open_app') IS NOT NULL THEN
        ALTER TABLE open_app_secret
            ADD CONSTRAINT fk_open_app_secret_app
            FOREIGN KEY (app_id) REFERENCES sys_open_app(id);
    END IF;
END $$;

COMMENT ON TABLE open_app_secret IS 'Open API Secret Management';
COMMENT ON COLUMN open_app_secret.id IS 'Primary Key (Snowflake ID)';
COMMENT ON COLUMN open_app_secret.app_id IS 'Application ID';
COMMENT ON COLUMN open_app_secret.secret_key IS 'Encrypted Secret Key';
COMMENT ON COLUMN open_app_secret.secret_version IS 'Secret Version Number';
COMMENT ON COLUMN open_app_secret.status IS 'Status: ACTIVE / EXPIRED';
COMMENT ON COLUMN open_app_secret.expire_time IS 'Expiration Time';
