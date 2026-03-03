-- V065: Create billing and help center tables

-- Table: bill_usage_record
CREATE TABLE bill_usage_record (
    id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    metric_type VARCHAR(50) NOT NULL,
    usage_value DECIMAL(18,4) NOT NULL DEFAULT 0,
    record_date DATE NOT NULL,
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

COMMENT ON TABLE bill_usage_record IS 'Tenant usage records';
COMMENT ON COLUMN bill_usage_record.metric_type IS 'Metric type: USER_COUNT/STORAGE_MB/API_CALLS/LOGIN_COUNT/FILE_COUNT';
COMMENT ON COLUMN bill_usage_record.usage_value IS 'Usage value';
COMMENT ON COLUMN bill_usage_record.record_date IS 'Record date (daily)';

CREATE UNIQUE INDEX uk_usage_tenant_metric_date ON bill_usage_record (tenant_id, metric_type, record_date) WHERE deleted = FALSE;
CREATE INDEX idx_usage_tenant_date ON bill_usage_record (tenant_id, record_date DESC);
CREATE INDEX idx_usage_metric_date ON bill_usage_record (metric_type, record_date DESC);

-- Table: sys_help_doc
CREATE TABLE sys_help_doc (
    id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    doc_key VARCHAR(100) NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    route_match VARCHAR(500),
    sort_order INT NOT NULL DEFAULT 0,
    status SMALLINT NOT NULL DEFAULT 1,
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

COMMENT ON TABLE sys_help_doc IS 'Help documentation';
COMMENT ON COLUMN sys_help_doc.tenant_id IS 'Tenant ID (0 = global doc visible to all tenants)';
COMMENT ON COLUMN sys_help_doc.doc_key IS 'Document unique key';
COMMENT ON COLUMN sys_help_doc.title IS 'Document title';
COMMENT ON COLUMN sys_help_doc.content IS 'Markdown content';
COMMENT ON COLUMN sys_help_doc.category IS 'Category';
COMMENT ON COLUMN sys_help_doc.route_match IS 'Associated frontend route (supports wildcard)';
COMMENT ON COLUMN sys_help_doc.sort_order IS 'Sort order';
COMMENT ON COLUMN sys_help_doc.status IS 'Status: 1 enabled, 0 disabled';

CREATE UNIQUE INDEX uk_helpdoc_tenant_key ON sys_help_doc (tenant_id, doc_key) WHERE deleted = FALSE;
CREATE INDEX idx_helpdoc_tenant_category ON sys_help_doc (tenant_id, category, status) WHERE deleted = FALSE;
CREATE INDEX idx_helpdoc_route ON sys_help_doc (route_match) WHERE deleted = FALSE AND route_match IS NOT NULL;
