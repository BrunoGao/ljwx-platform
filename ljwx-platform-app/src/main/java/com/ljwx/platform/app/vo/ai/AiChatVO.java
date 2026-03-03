package com.ljwx.platform.app.vo.ai;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * AI 对话响应 VO
 *
 * @author LJWX Platform
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiChatVO {

    /**
     * 会话 ID
     */
    private String sessionId;

    /**
     * AI 回答
     */
    private String answer;

    /**
     * Tool 调用摘要（名称+参数，不含原始结果）
     */
    private List<Map<String, Object>> toolCalls;

    /**
     * 消耗 Token 数
     */
    private Integer tokensUsed;

    /**
     * 响应耗时（毫秒）
     */
    private Long durationMs;
}
