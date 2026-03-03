-- Phase 40: 岗位管理 - sys_post 表
CREATE TABLE sys_post (
    id BIGINT NOT NULL,
    post_code VARCHAR(50) NOT NULL,
    post_name VARCHAR(100) NOT NULL,
    post_sort INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'ENABLED',
    remark VARCHAR(500),
    tenant_id BIGINT NOT NULL DEFAULT 0,
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_tenant_post_code ON sys_post (tenant_id, post_code, deleted);
CREATE INDEX idx_tenant_id ON sys_post (tenant_id);

COMMENT ON TABLE sys_post IS '岗位表';
COMMENT ON COLUMN sys_post.id IS '主键（雪花 ID）';
COMMENT ON COLUMN sys_post.post_code IS '岗位编码';
COMMENT ON COLUMN sys_post.post_name IS '岗位名称';
COMMENT ON COLUMN sys_post.post_sort IS '显示顺序';
COMMENT ON COLUMN sys_post.status IS '状态：ENABLED / DISABLED';
COMMENT ON COLUMN sys_post.remark IS '备注';
