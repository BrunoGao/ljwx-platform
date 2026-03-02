-- Phase 44: 角色自定义数据范围表
-- 用于存储角色的自定义部门数据范围

CREATE TABLE sys_role_data_scope (
    id           BIGINT       NOT NULL,
    role_id      BIGINT       NOT NULL,
    dept_id      BIGINT       NOT NULL,
    tenant_id    BIGINT       NOT NULL DEFAULT 0,
    created_by   BIGINT       NOT NULL DEFAULT 0,
    created_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by   BIGINT       NOT NULL DEFAULT 0,
    updated_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted      BOOLEAN      NOT NULL DEFAULT FALSE,
    version      INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- 唯一索引：同一租户下，同一角色不能重复绑定同一部门
CREATE UNIQUE INDEX uk_role_dept ON sys_role_data_scope (tenant_id, role_id, dept_id, deleted);

-- 索引：按角色查询
CREATE INDEX idx_role_id ON sys_role_data_scope (role_id);

-- 索引：按部门查询
CREATE INDEX idx_dept_id ON sys_role_data_scope (dept_id);

-- 索引：租户隔离
CREATE INDEX idx_tenant_id ON sys_role_data_scope (tenant_id);

COMMENT ON TABLE sys_role_data_scope IS '角色自定义数据范围表';
COMMENT ON COLUMN sys_role_data_scope.id IS '主键（雪花ID）';
COMMENT ON COLUMN sys_role_data_scope.role_id IS '角色ID';
COMMENT ON COLUMN sys_role_data_scope.dept_id IS '部门ID';
COMMENT ON COLUMN sys_role_data_scope.tenant_id IS '租户ID';
COMMENT ON COLUMN sys_role_data_scope.created_by IS '创建人';
COMMENT ON COLUMN sys_role_data_scope.created_time IS '创建时间';
COMMENT ON COLUMN sys_role_data_scope.updated_by IS '更新人';
COMMENT ON COLUMN sys_role_data_scope.updated_time IS '更新时间';
COMMENT ON COLUMN sys_role_data_scope.deleted IS '软删除标记';
COMMENT ON COLUMN sys_role_data_scope.version IS '乐观锁版本号';
