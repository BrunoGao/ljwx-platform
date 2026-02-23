-- =============================================================
-- V004: Create sys_permission and sys_role_permission
-- =============================================================

CREATE TABLE sys_permission (
    id            BIGINT        NOT NULL,
    code          VARCHAR(100)  NOT NULL,
    name          VARCHAR(200),
    remark        VARCHAR(500),

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id     BIGINT        NOT NULL DEFAULT 0,
    created_by    BIGINT        NOT NULL DEFAULT 0,
    created_time  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by    BIGINT        NOT NULL DEFAULT 0,
    updated_time  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted       BOOLEAN       NOT NULL DEFAULT FALSE,
    version       INT           NOT NULL DEFAULT 1,

    PRIMARY KEY (id),
    UNIQUE (tenant_id, code)
);

CREATE TABLE sys_role_permission (
    id             BIGINT    NOT NULL,
    role_id        BIGINT    NOT NULL,
    permission_id  BIGINT    NOT NULL,

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id      BIGINT    NOT NULL DEFAULT 0,
    created_by     BIGINT    NOT NULL DEFAULT 0,
    created_time   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by     BIGINT    NOT NULL DEFAULT 0,
    updated_time   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted        BOOLEAN   NOT NULL DEFAULT FALSE,
    version        INT       NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

COMMENT ON TABLE  sys_permission         IS '权限表（resource:action 格式）';
COMMENT ON COLUMN sys_permission.code    IS '权限字符串，如 user:read';
COMMENT ON COLUMN sys_permission.deleted IS '软删除标志';
COMMENT ON COLUMN sys_permission.version IS '乐观锁版本号';
COMMENT ON TABLE  sys_role_permission    IS '角色-权限关联表';
