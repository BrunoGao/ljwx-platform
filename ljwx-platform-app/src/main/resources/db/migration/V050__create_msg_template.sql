-- Phase 50: Message Template Management
-- Create msg_template table

CREATE TABLE msg_template (
    id              BIGINT          NOT NULL,
    template_code   VARCHAR(50)     NOT NULL,
    template_name   VARCHAR(100)    NOT NULL,
    template_type   VARCHAR(20)     NOT NULL,
    subject         VARCHAR(200),
    content         TEXT            NOT NULL,
    variables       TEXT,
    status          VARCHAR(20)     NOT NULL,
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

-- Indexes
CREATE UNIQUE INDEX uk_template_code ON msg_template(template_code) WHERE deleted = FALSE;
CREATE INDEX idx_template_type ON msg_template(template_type);
CREATE INDEX idx_msg_template_status ON msg_template(status);
CREATE INDEX idx_msg_template_tenant_id ON msg_template(tenant_id);

COMMENT ON TABLE msg_template IS '消息模板表';
COMMENT ON COLUMN msg_template.id IS '主键（雪花ID）';
COMMENT ON COLUMN msg_template.template_code IS '模板编码';
COMMENT ON COLUMN msg_template.template_name IS '模板名称';
COMMENT ON COLUMN msg_template.template_type IS '模板类型: INBOX/EMAIL/SMS';
COMMENT ON COLUMN msg_template.subject IS '邮件主题';
COMMENT ON COLUMN msg_template.content IS '模板内容';
COMMENT ON COLUMN msg_template.variables IS 'JSON数组，变量列表';
COMMENT ON COLUMN msg_template.status IS '状态: ENABLED/DISABLED';
