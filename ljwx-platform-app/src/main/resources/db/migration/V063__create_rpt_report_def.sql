-- Phase 55: Report Engine - Report Definition Table
-- Description: Create rpt_report_def table for storing report definitions

CREATE TABLE rpt_report_def (
    id                BIGINT       NOT NULL,
    tenant_id         BIGINT       NOT NULL DEFAULT 0,
    report_name       VARCHAR(100) NOT NULL,
    report_key        VARCHAR(100) NOT NULL,
    data_source_type  VARCHAR(20)  NOT NULL DEFAULT 'SQL',
    query_template    TEXT         NOT NULL,
    column_def        JSONB        NOT NULL,
    filter_def        JSONB        NULL,
    status            SMALLINT     NOT NULL DEFAULT 1,
    remark            VARCHAR(500) NULL,
    created_by        BIGINT       NOT NULL DEFAULT 0,
    created_time      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by        BIGINT       NOT NULL DEFAULT 0,
    updated_time      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted           BOOLEAN      NOT NULL DEFAULT FALSE,
    version           INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Unique constraint: report_key must be unique within tenant
CREATE UNIQUE INDEX uk_report_tenant_key ON rpt_report_def (tenant_id, report_key) WHERE deleted = FALSE;

-- Index for listing reports by tenant and status
CREATE INDEX idx_report_tenant_status ON rpt_report_def (tenant_id, status) WHERE deleted = FALSE;

COMMENT ON TABLE rpt_report_def IS 'Report definition table';
COMMENT ON COLUMN rpt_report_def.id IS 'Primary key (Snowflake ID)';
COMMENT ON COLUMN rpt_report_def.tenant_id IS 'Tenant ID';
COMMENT ON COLUMN rpt_report_def.report_name IS 'Report name';
COMMENT ON COLUMN rpt_report_def.report_key IS 'Report unique identifier';
COMMENT ON COLUMN rpt_report_def.data_source_type IS 'Data source type (MVP only supports SQL for PostgreSQL)';
COMMENT ON COLUMN rpt_report_def.query_template IS 'SQL query template (using #{paramName} placeholders)';
COMMENT ON COLUMN rpt_report_def.column_def IS 'Column definition (column name, title, type, width, format)';
COMMENT ON COLUMN rpt_report_def.filter_def IS 'Filter definition (parameter name, type, label, required)';
