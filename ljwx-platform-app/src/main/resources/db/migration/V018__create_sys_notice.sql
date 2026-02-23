-- =============================================================
-- V018: Create sys_notice — system notice / announcement
-- =============================================================

CREATE TABLE sys_notice (
    id              BIGINT        NOT NULL,
    notice_title    VARCHAR(255)  NOT NULL DEFAULT '',
    notice_type     SMALLINT      NOT NULL DEFAULT 1,
    notice_content  TEXT,
    status          SMALLINT      NOT NULL DEFAULT 0,
    publish_time    TIMESTAMP,

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

CREATE INDEX idx_notice_tenant_time ON sys_notice (tenant_id, created_time DESC);
CREATE INDEX idx_notice_status      ON sys_notice (status);
CREATE INDEX idx_notice_type        ON sys_notice (notice_type);

COMMENT ON TABLE  sys_notice                  IS '系统通知/公告表';
COMMENT ON COLUMN sys_notice.id               IS '主键ID（Snowflake）';
COMMENT ON COLUMN sys_notice.notice_title     IS '通知标题';
COMMENT ON COLUMN sys_notice.notice_type      IS '通知类型：1-通知,2-公告';
COMMENT ON COLUMN sys_notice.notice_content   IS '通知内容';
COMMENT ON COLUMN sys_notice.status           IS '状态：0-草稿,1-已发布,2-已撤回';
COMMENT ON COLUMN sys_notice.publish_time     IS '发布时间';
COMMENT ON COLUMN sys_notice.tenant_id        IS '租户ID，由 TenantLineInterceptor 自动注入';
COMMENT ON COLUMN sys_notice.deleted          IS '软删除标志';
COMMENT ON COLUMN sys_notice.version          IS '乐观锁版本号';
