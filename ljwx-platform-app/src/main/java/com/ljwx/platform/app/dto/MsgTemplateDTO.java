package com.ljwx.platform.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 消息模板DTO
 *
 * @author LJWX Platform
 * @since Phase 50
 */
@Data
public class MsgTemplateDTO {

    /**
     * 模板编码
     */
    @NotBlank(message = "模板编码不能为空")
    @Size(max = 50, message = "模板编码长度不能超过50")
    private String templateCode;

    /**
     * 模板名称
     */
    @NotBlank(message = "模板名称不能为空")
    @Size(max = 100, message = "模板名称长度不能超过100")
    private String templateName;

    /**
     * 模板类型: INBOX / EMAIL / SMS
     */
    @NotBlank(message = "模板类型不能为空")
    private String templateType;

    /**
     * 邮件主题
     */
    @Size(max = 200, message = "邮件主题长度不能超过200")
    private String subject;

    /**
     * 模板内容
     */
    @NotBlank(message = "模板内容不能为空")
    private String content;

    /**
     * JSON数组，变量列表
     */
    private String variables;

    /**
     * 状态: ENABLED / DISABLED
     */
    @NotBlank(message = "状态不能为空")
    private String status;
}
