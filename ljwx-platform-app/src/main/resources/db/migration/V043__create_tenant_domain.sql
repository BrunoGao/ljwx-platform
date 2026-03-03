-- Phase 43: 租户域名识别 (Tenant Domain Recognition)
-- 创建租户域名表

CREATE TABLE sys_tenant_domain (
    id              BIGINT          NOT NULL,
    domain          VARCHAR(200)    NOT NULL,
    tenant_id       BIGINT          NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'ENABLED',
    is_primary      BOOLEAN         NOT NULL DEFAULT FALSE,
    verified        BOOLEAN         NOT NULL DEFAULT FALSE,
    verified_time   TIMESTAMP,
    verify_token    VARCHAR(100),
    remark          VARCHAR(500),
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- 索引
CREATE UNIQUE INDEX uk_tenant_domain_domain_deleted ON sys_tenant_domain (domain, deleted);
CREATE INDEX idx_tenant_domain_tenant_id ON sys_tenant_domain (tenant_id);
CREATE INDEX idx_tenant_domain_status ON sys_tenant_domain (status);

-- 注释
COMMENT ON TABLE sys_tenant_domain IS '租户域名表';
COMMENT ON COLUMN sys_tenant_domain.id IS '主键（雪花 ID）';
COMMENT ON COLUMN sys_tenant_domain.domain IS '域名';
COMMENT ON COLUMN sys_tenant_domain.tenant_id IS '租户 ID（业务字段，非审计字段）';
COMMENT ON COLUMN sys_tenant_domain.status IS '状态：ENABLED / DISABLED';
COMMENT ON COLUMN sys_tenant_domain.is_primary IS '是否主域名';
COMMENT ON COLUMN sys_tenant_domain.verified IS '是否已验证';
COMMENT ON COLUMN sys_tenant_domain.verified_time IS '验证时间';
COMMENT ON COLUMN sys_tenant_domain.verify_token IS '验证 token';
COMMENT ON COLUMN sys_tenant_domain.remark IS '备注';
COMMENT ON COLUMN sys_tenant_domain.created_by IS '创建人';
COMMENT ON COLUMN sys_tenant_domain.created_time IS '创建时间';
COMMENT ON COLUMN sys_tenant_domain.updated_by IS '更新人';
COMMENT ON COLUMN sys_tenant_domain.updated_time IS '更新时间';
COMMENT ON COLUMN sys_tenant_domain.deleted IS '软删除标记';
COMMENT ON COLUMN sys_tenant_domain.version IS '乐观锁版本号';
