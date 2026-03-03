-- Phase 56: AI 智能运维助手
-- 创建 AI 配置表和对话日志表

-- sys_ai_config: AI 配置表
CREATE TABLE sys_ai_config (
    id                  BIGINT       NOT NULL,
    tenant_id           BIGINT       NOT NULL DEFAULT 0,
    provider            VARCHAR(50)  NOT NULL,
    model_name          VARCHAR(100) NOT NULL,
    api_key_encrypted   TEXT         NOT NULL,
    base_url            VARCHAR(500),
    temperature         DECIMAL(3,2) NOT NULL DEFAULT 0.70,
    max_tokens          INT          NOT NULL DEFAULT 2048,
    enabled             BOOLEAN      NOT NULL DEFAULT TRUE,
    created_by          BIGINT       NOT NULL DEFAULT 0,
    created_time        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT       NOT NULL DEFAULT 0,
    updated_time        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted             BOOLEAN      NOT NULL DEFAULT FALSE,
    version             INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_ai_config_tenant ON sys_ai_config (tenant_id) WHERE deleted = FALSE AND enabled = TRUE;
CREATE INDEX idx_ai_config_tenant ON sys_ai_config (tenant_id);

COMMENT ON TABLE sys_ai_config IS 'AI 配置表';
COMMENT ON COLUMN sys_ai_config.provider IS '模型提供商（OPENAI/TONGYI/DEEPSEEK）';
COMMENT ON COLUMN sys_ai_config.model_name IS '模型名称';
COMMENT ON COLUMN sys_ai_config.api_key_encrypted IS '加密存储的 API Key';
COMMENT ON COLUMN sys_ai_config.base_url IS '自定义 API Base URL';
COMMENT ON COLUMN sys_ai_config.temperature IS '温度参数（0.00-1.00）';
COMMENT ON COLUMN sys_ai_config.max_tokens IS '最大 Token 数';
COMMENT ON COLUMN sys_ai_config.enabled IS '是否启用';

-- sys_ai_conversation_log: AI 对话日志表
CREATE TABLE sys_ai_conversation_log (
    id              BIGINT       NOT NULL,
    tenant_id       BIGINT       NOT NULL DEFAULT 0,
    user_id         BIGINT       NOT NULL DEFAULT 0,
    session_id      VARCHAR(64)  NOT NULL,
    question        TEXT         NOT NULL,
    answer          TEXT         NOT NULL,
    tool_calls      JSONB,
    tokens_used     INT          NOT NULL DEFAULT 0,
    duration_ms     INT          NOT NULL DEFAULT 0,
    model_name      VARCHAR(100) NOT NULL,
    created_by      BIGINT       NOT NULL DEFAULT 0,
    created_time    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT       NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN      NOT NULL DEFAULT FALSE,
    version         INT          NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

CREATE INDEX idx_ai_log_tenant_user ON sys_ai_conversation_log (tenant_id, user_id, created_time DESC);
CREATE INDEX idx_ai_log_session ON sys_ai_conversation_log (session_id);

COMMENT ON TABLE sys_ai_conversation_log IS 'AI 对话日志表';
COMMENT ON COLUMN sys_ai_conversation_log.session_id IS '会话 ID';
COMMENT ON COLUMN sys_ai_conversation_log.question IS '用户提问';
COMMENT ON COLUMN sys_ai_conversation_log.answer IS 'AI 回答';
COMMENT ON COLUMN sys_ai_conversation_log.tool_calls IS 'Tool 调用链（JSONB）';
COMMENT ON COLUMN sys_ai_conversation_log.tokens_used IS '消耗 Token 数';
COMMENT ON COLUMN sys_ai_conversation_log.duration_ms IS '响应耗时（毫秒）';
COMMENT ON COLUMN sys_ai_conversation_log.model_name IS '使用的模型名称';
