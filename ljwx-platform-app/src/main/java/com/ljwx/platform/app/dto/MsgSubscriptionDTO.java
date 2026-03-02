package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 消息订阅 DTO
 *
 * @author LJWX Platform
 * @since Phase 52
 */
@Data
public class MsgSubscriptionDTO {

    /**
     * 用户 ID
     */
    @NotNull(message = "用户ID不能为空")
    private Long userId;

    /**
     * 模板 ID
     */
    @NotNull(message = "模板ID不能为空")
    private Long templateId;

    /**
     * 订阅渠道: EMAIL / SMS / WECHAT / PUSH
     */
    @NotBlank(message = "渠道不能为空")
    private String channel;

    /**
     * 订阅状态: ACTIVE / INACTIVE
     */
    @NotBlank(message = "状态不能为空")
    private String status;

    /**
     * 订阅偏好（频率、时段等）- JSONB 存储
     */
    private String preference;
}
