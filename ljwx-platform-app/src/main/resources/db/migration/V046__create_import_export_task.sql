-- Phase 46: Import/Export Center
-- Create sys_import_export_task table

CREATE TABLE sys_import_export_task (
    id              BIGINT          NOT NULL,
    task_type       VARCHAR(20)     NOT NULL,
    business_type   VARCHAR(50)     NOT NULL,
    file_name       VARCHAR(200)    NOT NULL,
    file_url        VARCHAR(500),
    status          VARCHAR(20)     NOT NULL,
    total_count     INT             NOT NULL DEFAULT 0,
    success_count   INT             NOT NULL DEFAULT 0,
    failure_count   INT             NOT NULL DEFAULT 0,
    error_message   TEXT,
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

COMMENT ON TABLE sys_import_export_task IS 'Import/Export task table';
COMMENT ON COLUMN sys_import_export_task.id IS 'Primary key (Snowflake ID)';
COMMENT ON COLUMN sys_import_export_task.task_type IS 'Task type: IMPORT / EXPORT';
COMMENT ON COLUMN sys_import_export_task.business_type IS 'Business type: USER / ROLE / DEPT / MENU';
COMMENT ON COLUMN sys_import_export_task.file_name IS 'File name';
COMMENT ON COLUMN sys_import_export_task.file_url IS 'File URL (MinIO)';
COMMENT ON COLUMN sys_import_export_task.status IS 'Status: PENDING / PROCESSING / SUCCESS / FAILURE';
COMMENT ON COLUMN sys_import_export_task.total_count IS 'Total record count';
COMMENT ON COLUMN sys_import_export_task.success_count IS 'Success record count';
COMMENT ON COLUMN sys_import_export_task.failure_count IS 'Failure record count';
COMMENT ON COLUMN sys_import_export_task.error_message IS 'Error message';

CREATE INDEX idx_import_export_task_status ON sys_import_export_task(status);
CREATE INDEX idx_import_export_task_tenant_id ON sys_import_export_task(tenant_id);
CREATE INDEX idx_import_export_task_created_time ON sys_import_export_task(created_time);
