-- =============================================================
-- V017: Create sys_file — file management
-- =============================================================

CREATE TABLE sys_file (
    id           BIGINT        NOT NULL,
    file_name    VARCHAR(255)  NOT NULL DEFAULT '',
    file_path    VARCHAR(1000) NOT NULL DEFAULT '',
    file_size    BIGINT        NOT NULL DEFAULT 0,
    file_type    VARCHAR(50)   NOT NULL DEFAULT '',
    content_type VARCHAR(200)  NOT NULL DEFAULT '',

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id    BIGINT     NOT NULL DEFAULT 0,
    created_by   BIGINT     NOT NULL DEFAULT 0,
    created_time TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by   BIGINT     NOT NULL DEFAULT 0,
    updated_time TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted      BOOLEAN    NOT NULL DEFAULT FALSE,
    version      INT        NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

CREATE INDEX idx_file_tenant_time ON sys_file (tenant_id, created_time DESC);
CREATE INDEX idx_file_type        ON sys_file (file_type);

COMMENT ON TABLE  sys_file               IS '文件管理表';
COMMENT ON COLUMN sys_file.id            IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_file.file_name     IS '原始文件名';
COMMENT ON COLUMN sys_file.file_path     IS '存储路径（相对于 base-path）';
COMMENT ON COLUMN sys_file.file_size     IS '文件大小（字节）';
COMMENT ON COLUMN sys_file.file_type     IS '文件后缀（如 jpg、pdf）';
COMMENT ON COLUMN sys_file.content_type  IS 'MIME 类型';
COMMENT ON COLUMN sys_file.tenant_id     IS '租户ID，路径含 tenant_id，由 TenantLineInterceptor 注入';
COMMENT ON COLUMN sys_file.deleted       IS '软删除标志';
COMMENT ON COLUMN sys_file.version       IS '乐观锁版本号';
