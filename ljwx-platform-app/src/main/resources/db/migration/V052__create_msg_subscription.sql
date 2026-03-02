-- Phase 52: 消息订阅管理表
-- 用户订阅消息模板,支持多渠道订阅配置

CREATE TABLE msg_subscription (
    id              BIGINT          NOT NULL,
    user_id         BIGINT          NOT NULL,
    template_id     BIGINT          NOT NULL,
    channel         VARCHAR(20)     NOT NULL,
    status          VARCHAR(20)     NOT NULL,
    preference      JSONB,
    tenant_id       BIGINT          NOT NULL DEFAULT 0,
    created_by      BIGINT          NOT NULL DEFAULT 0,
    created_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL DEFAULT 0,
    updated_time    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted         BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    PRIMARY KEY (id)
);

COMMENT ON TABLE msg_subscription IS '消息订阅表';
COMMENT ON COLUMN msg_subscription.id IS '主键（雪花 ID）';
COMMENT ON COLUMN msg_subscription.user_id IS '用户 ID';
COMMENT ON COLUMN msg_subscription.template_id IS '模板 ID';
COMMENT ON COLUMN msg_subscription.channel IS '订阅渠道: EMAIL / SMS / WECHAT / PUSH';
COMMENT ON COLUMN msg_subscription.status IS '订阅状态: ACTIVE / INACTIVE';
COMMENT ON COLUMN msg_subscription.preference IS '订阅偏好（频率、时段等）';
COMMENT ON COLUMN msg_subscription.tenant_id IS '租户 ID';
COMMENT ON COLUMN msg_subscription.created_by IS '创建人';
COMMENT ON COLUMN msg_subscription.created_time IS '创建时间';
COMMENT ON COLUMN msg_subscription.updated_by IS '更新人';
COMMENT ON COLUMN msg_subscription.updated_time IS '更新时间';
COMMENT ON COLUMN msg_subscription.deleted IS '软删除标记';
COMMENT ON COLUMN msg_subscription.version IS '乐观锁版本号';

-- 索引
CREATE INDEX idx_msg_subscription_user_id ON msg_subscription(user_id);
CREATE INDEX idx_msg_subscription_template_id ON msg_subscription(template_id);
CREATE INDEX idx_msg_subscription_status ON msg_subscription(status);
CREATE INDEX idx_msg_subscription_tenant_id ON msg_subscription(tenant_id);

-- 唯一约束：同一用户+模板+渠道只能订阅一次
CREATE UNIQUE INDEX uk_msg_subscription_user_template_channel ON msg_subscription(user_id, template_id, channel) WHERE deleted = FALSE;
