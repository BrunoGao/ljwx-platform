package com.ljwx.platform.app.dto.ai;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * AI 对话请求 DTO
 *
 * @author LJWX Platform
 */
@Data
public class AiChatDTO {

    /**
     * 会话 ID（空则生成新会话）
     */
    @Size(max = 64, message = "会话 ID 长度不能超过 64 个字符")
    @Pattern(regexp = "[a-zA-Z0-9_-]*", message = "会话 ID 仅允许字母、数字、下划线、短横线")
    private String sessionId;

    /**
     * 用户提问
     */
    @jakarta.validation.constraints.NotBlank(message = "提问内容不能为空")
    @Size(min = 1, max = 2000, message = "提问内容长度必须在 1-2000 个字符之间")
    private String message;
}
