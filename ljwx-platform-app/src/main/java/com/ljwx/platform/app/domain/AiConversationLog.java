package com.ljwx.platform.app.domain;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.ljwx.platform.data.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;
import java.util.Map;

/**
 * AI 对话日志实体
 *
 * @author LJWX Platform
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName(value = "sys_ai_conversation_log", autoResultMap = true)
public class AiConversationLog extends BaseEntity {

    /**
     * 用户 ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 会话 ID
     */
    @TableField("session_id")
    private String sessionId;

    /**
     * 用户提问
     */
    @TableField("question")
    private String question;

    /**
     * AI 回答
     */
    @TableField("answer")
    private String answer;

    /**
     * Tool 调用链（JSONB）
     */
    @TableField(value = "tool_calls", typeHandler = JacksonTypeHandler.class)
    private List<Map<String, Object>> toolCalls;

    /**
     * 消耗 Token 数
     */
    @TableField("tokens_used")
    private Integer tokensUsed;

    /**
     * 响应耗时（毫秒）
     */
    @TableField("duration_ms")
    private Long durationMs;

    /**
     * 使用的模型名称
     */
    @TableField("model_name")
    private String modelName;
}
