-- V061: Create sys_form_def and sys_form_data tables

-- sys_form_def: Form definition with JSON Schema
CREATE TABLE sys_form_def (
    id BIGINT PRIMARY KEY,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    form_name VARCHAR(100) NOT NULL,
    form_key VARCHAR(100) NOT NULL,
    schema JSONB NOT NULL,
    status SMALLINT NOT NULL DEFAULT 1,
    remark VARCHAR(500),
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX uk_form_tenant_key ON sys_form_def (tenant_id, form_key) WHERE deleted = FALSE;
CREATE INDEX idx_form_tenant_status ON sys_form_def (tenant_id, status) WHERE deleted = FALSE;

COMMENT ON TABLE sys_form_def IS 'Form definition table';
COMMENT ON COLUMN sys_form_def.id IS 'Primary key (Snowflake ID)';
COMMENT ON COLUMN sys_form_def.tenant_id IS 'Tenant ID';
COMMENT ON COLUMN sys_form_def.form_name IS 'Form name';
COMMENT ON COLUMN sys_form_def.form_key IS 'Form unique key';
COMMENT ON COLUMN sys_form_def.schema IS 'Form JSON Schema (fields, validation, layout)';
COMMENT ON COLUMN sys_form_def.status IS 'Status: 1=enabled, 0=disabled';
COMMENT ON COLUMN sys_form_def.remark IS 'Remark';

-- sys_form_data: Form data with JSONB field values
CREATE TABLE sys_form_data (
    id BIGINT PRIMARY KEY,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    form_def_id BIGINT NOT NULL,
    field_values JSONB NOT NULL,
    creator_id BIGINT NOT NULL DEFAULT 0,
    creator_dept_id BIGINT NOT NULL DEFAULT 0,
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1
);

CREATE INDEX idx_formdata_tenant_formdef ON sys_form_data (tenant_id, form_def_id) WHERE deleted = FALSE;
CREATE INDEX idx_formdata_creator ON sys_form_data (tenant_id, creator_id) WHERE deleted = FALSE;
CREATE INDEX idx_gin_formdata_field_values ON sys_form_data USING GIN (field_values jsonb_path_ops);

COMMENT ON TABLE sys_form_data IS 'Form data table';
COMMENT ON COLUMN sys_form_data.id IS 'Primary key (Snowflake ID)';
COMMENT ON COLUMN sys_form_data.tenant_id IS 'Tenant ID';
COMMENT ON COLUMN sys_form_data.form_def_id IS 'Form definition ID';
COMMENT ON COLUMN sys_form_data.field_values IS 'Form field values (JSON object)';
COMMENT ON COLUMN sys_form_data.creator_id IS 'Creator user ID';
COMMENT ON COLUMN sys_form_data.creator_dept_id IS 'Creator department ID';
