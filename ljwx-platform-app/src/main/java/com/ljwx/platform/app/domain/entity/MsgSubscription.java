package com.ljwx.platform.app.domain.entity;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 消息订阅实体
 *
 * @author LJWX Platform
 * @since Phase 52
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class MsgSubscription extends BaseEntity {

    /**
     * 主键（雪花 ID）
     */
    private Long id;

    /**
     * 用户 ID
     */
    private Long userId;

    /**
     * 模板 ID
     */
    private Long templateId;

    /**
     * 订阅渠道: EMAIL / SMS / WECHAT / PUSH
     */
    private String channel;

    /**
     * 订阅状态: ACTIVE / INACTIVE
     */
    private String status;

    /**
     * 订阅偏好（频率、时段等）- JSONB 存储
     */
    private String preference;
}
