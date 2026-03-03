-- Phase 40: 岗位管理 - sys_user_post 关联表
CREATE TABLE sys_user_post (
    id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    post_id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL DEFAULT 0,
    created_by BIGINT NOT NULL DEFAULT 0,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL DEFAULT 0,
    updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    version INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_user_post ON sys_user_post (tenant_id, user_id, post_id, deleted);
CREATE INDEX idx_user_id ON sys_user_post (user_id);
CREATE INDEX idx_post_id ON sys_user_post (post_id);
CREATE INDEX idx_tenant_id ON sys_user_post (tenant_id);

COMMENT ON TABLE sys_user_post IS '用户岗位关联表';
COMMENT ON COLUMN sys_user_post.id IS '主键（雪花 ID）';
COMMENT ON COLUMN sys_user_post.user_id IS '用户 ID';
COMMENT ON COLUMN sys_user_post.post_id IS '岗位 ID';
