-- V062: Create sys_custom_field_def table

CREATE TABLE sys_custom_field_def (
    id BIGINT PRIMARY KEY,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    entity_type VARCHAR(50) NOT NULL,
    field_key VARCHAR(100) NOT NULL,
    field_label VARCHAR(100) NOT NULL,
    field_type VARCHAR(50) NOT NULL,
    required BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    options JSONB,
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX uk_customfield_tenant_entity_key ON sys_custom_field_def (tenant_id, entity_type, field_key) WHERE deleted = FALSE;
CREATE INDEX idx_customfield_tenant_entity ON sys_custom_field_def (tenant_id, entity_type) WHERE deleted = FALSE;

COMMENT ON TABLE sys_custom_field_def IS 'Custom field definition table';
COMMENT ON COLUMN sys_custom_field_def.id IS 'Primary key (Snowflake ID)';
COMMENT ON COLUMN sys_custom_field_def.tenant_id IS 'Tenant ID';
COMMENT ON COLUMN sys_custom_field_def.entity_type IS 'Entity type (USER/DEPT/...)';
COMMENT ON COLUMN sys_custom_field_def.field_key IS 'Field unique key';
COMMENT ON COLUMN sys_custom_field_def.field_label IS 'Field display label';
COMMENT ON COLUMN sys_custom_field_def.field_type IS 'Field type (TEXT/NUMBER/DATE/SELECT/CHECKBOX)';
COMMENT ON COLUMN sys_custom_field_def.required IS 'Is required';
COMMENT ON COLUMN sys_custom_field_def.sort_order IS 'Sort order';
COMMENT ON COLUMN sys_custom_field_def.options IS 'Options for SELECT/CHECKBOX (JSON array)';
