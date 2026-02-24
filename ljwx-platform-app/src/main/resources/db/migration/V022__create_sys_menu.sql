-- =============================================================
-- V022: Create sys_menu table
-- Menu types: 0=directory 1=menu 2=button
-- Contains 7 mandatory audit columns (spec/01-constraints.md §审计字段)
-- =============================================================

CREATE TABLE sys_menu (
    id           BIGINT        NOT NULL,
    parent_id    BIGINT        NOT NULL DEFAULT 0,
    name         VARCHAR(64)   NOT NULL,
    path         VARCHAR(200)  NOT NULL DEFAULT '',
    component    VARCHAR(200)  NOT NULL DEFAULT '',
    icon         VARCHAR(100)  NOT NULL DEFAULT '',
    sort         INT           NOT NULL DEFAULT 0,
    menu_type    SMALLINT      NOT NULL DEFAULT 0,
    permission   VARCHAR(100)  NOT NULL DEFAULT '',
    visible      SMALLINT      NOT NULL DEFAULT 1,
    -- 7 audit columns — required for all business tables
    tenant_id    BIGINT        NOT NULL DEFAULT 0,
    created_by   BIGINT        NOT NULL DEFAULT 0,
    created_time TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by   BIGINT        NOT NULL DEFAULT 0,
    updated_time TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted      BOOLEAN       NOT NULL DEFAULT FALSE,
    version      INT           NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

CREATE INDEX idx_menu_tenant_parent  ON sys_menu (tenant_id, parent_id) WHERE deleted = FALSE;
CREATE INDEX idx_menu_tenant_sort    ON sys_menu (tenant_id, sort)      WHERE deleted = FALSE;
