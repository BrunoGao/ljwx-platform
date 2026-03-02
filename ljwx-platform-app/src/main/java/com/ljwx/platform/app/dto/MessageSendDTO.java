package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.Map;

/**
 * 消息发送DTO
 *
 * @author LJWX Platform
 * @since Phase 51
 */
@Data
public class MessageSendDTO {

    /**
     * 消息模板ID
     */
    @NotNull(message = "消息模板ID不能为空")
    private Long templateId;

    /**
     * 消息类型: INBOX / EMAIL / SMS
     */
    @NotBlank(message = "消息类型不能为空")
    private String messageType;

    /**
     * 接收用户ID
     */
    @NotNull(message = "接收用户ID不能为空")
    private Long receiverId;

    /**
     * 接收地址（邮箱/手机号，EMAIL/SMS必填）
     */
    private String receiverAddress;

    /**
     * 消息主题
     */
    @NotBlank(message = "消息主题不能为空")
    private String subject;

    /**
     * 消息内容
     */
    @NotBlank(message = "消息内容不能为空")
    private String content;

    /**
     * 模板参数
     */
    private Map<String, Object> params;
}
