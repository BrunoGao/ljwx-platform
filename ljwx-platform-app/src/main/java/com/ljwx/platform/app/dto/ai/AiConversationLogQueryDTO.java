package com.ljwx.platform.app.dto.ai;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * AI 对话日志查询 DTO
 *
 * @author LJWX Platform
 */
@Data
public class AiConversationLogQueryDTO {

    /**
     * 会话 ID
     */
    private String sessionId;

    /**
     * 用户 ID
     */
    private Long userId;

    /**
     * 开始时间
     */
    private LocalDateTime startTime;

    /**
     * 结束时间
     */
    private LocalDateTime endTime;

    /**
     * 页码
     */
    private Integer pageNum = 1;

    /**
     * 每页大小
     */
    private Integer pageSize = 10;

    /**
     * 计算偏移量
     */
    public Integer getOffset() {
        return (pageNum - 1) * pageSize;
    }
}
