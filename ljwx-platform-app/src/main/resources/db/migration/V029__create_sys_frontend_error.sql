-- V029: 创建前端错误监控表
CREATE TABLE sys_frontend_error (
    id              BIGINT          NOT NULL,
    error_message   VARCHAR(1000)   NOT NULL,
    stack_trace     TEXT            NOT NULL DEFAULT '',
    page_url        VARCHAR(500)    NOT NULL DEFAULT '',
    user_agent      VARCHAR(500)    NOT NULL DEFAULT '',
    -- 7 audit columns
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

COMMENT ON TABLE sys_frontend_error IS '前端错误监控表';
COMMENT ON COLUMN sys_frontend_error.id IS '主键';
COMMENT ON COLUMN sys_frontend_error.error_message IS '错误信息';
COMMENT ON COLUMN sys_frontend_error.stack_trace IS '堆栈信息';
COMMENT ON COLUMN sys_frontend_error.page_url IS '发生页面';
COMMENT ON COLUMN sys_frontend_error.user_agent IS '浏览器信息';
