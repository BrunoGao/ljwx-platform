package com.ljwx.platform.app.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 消息订阅 VO
 *
 * @author LJWX Platform
 * @since Phase 52
 */
@Data
public class MsgSubscriptionVO {

    /**
     * 主键
     */
    private Long id;

    /**
     * 用户 ID
     */
    private Long userId;

    /**
     * 用户名
     */
    private String userName;

    /**
     * 模板 ID
     */
    private Long templateId;

    /**
     * 模板名称
     */
    private String templateName;

    /**
     * 订阅渠道
     */
    private String channel;

    /**
     * 订阅状态
     */
    private String status;

    /**
     * 订阅偏好
     */
    private String preference;

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;
}
