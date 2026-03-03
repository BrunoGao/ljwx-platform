package com.ljwx.platform.app.vo.ai;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * AI 对话日志 VO
 *
 * @author LJWX Platform
 */
@Data
public class AiConversationLogVO {

    /**
     * 主键
     */
    private Long id;

    /**
     * 会话 ID
     */
    private String sessionId;

    /**
     * 用户提问
     */
    private String question;

    /**
     * AI 回答
     */
    private String answer;

    /**
     * Tool 调用名称摘要（不含原始参数和返回值）
     */
    private List<String> toolCallSummary;

    /**
     * 消耗 Token 数
     */
    private Integer tokensUsed;

    /**
     * 响应耗时（毫秒）
     */
    private Long durationMs;

    /**
     * 使用的模型名称
     */
    private String modelName;

    /**
     * 创建时间
     */
    private LocalDateTime createdTime;
}
