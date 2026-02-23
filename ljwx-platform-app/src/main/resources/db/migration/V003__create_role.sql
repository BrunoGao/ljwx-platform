-- =============================================================
-- V003: Create sys_role and sys_user_role
-- =============================================================

CREATE TABLE sys_role (
    id            BIGINT        NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    code          VARCHAR(50)   NOT NULL,
    status        SMALLINT      NOT NULL DEFAULT 1,
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

CREATE TABLE sys_user_role (
    id            BIGINT    NOT NULL,
    user_id       BIGINT    NOT NULL,
    role_id       BIGINT    NOT NULL,

    -- 7 audit columns (spec/01-constraints.md §审计字段)
    tenant_id     BIGINT    NOT NULL DEFAULT 0,
    created_by    BIGINT    NOT NULL DEFAULT 0,
    created_time  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by    BIGINT    NOT NULL DEFAULT 0,
    updated_time  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted       BOOLEAN   NOT NULL DEFAULT FALSE,
    version       INT       NOT NULL DEFAULT 1,

    PRIMARY KEY (id)
);

COMMENT ON TABLE  sys_role          IS '角色表';
COMMENT ON COLUMN sys_role.code     IS '角色编码（租户内唯一）';
COMMENT ON COLUMN sys_role.deleted  IS '软删除标志';
COMMENT ON COLUMN sys_role.version  IS '乐观锁版本号';
COMMENT ON TABLE  sys_user_role     IS '用户-角色关联表';
