package com.ljwx.platform.core.event;

import com.ljwx.platform.core.entity.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * Outbox 事件实体。
 *
 * <p>用于实现 Outbox 模式，保证"写库+发消息"的原子性。
 * 业务事务中插入 PENDING 事件，后台轮询器定期扫描并发送。
 *
 * <p>状态流转：
 * <pre>
 *   PENDING → SENT（成功）
 *   PENDING → FAILED（达到最大重试次数）
 * </pre>
 *
 * <p>重试策略：指数退避，next_retry_time = now + 2^retry_count * 60s，最大 30 分钟。
 */
@Data
@EqualsAndHashCode(callSuper = true)
public class OutboxEvent extends BaseEntity {

    /** 主键（雪花 ID） */
    private Long id;

    /** 聚合根类型（如 "User", "Order"） */
    private String aggregateType;

    /** 聚合根 ID */
    private Long aggregateId;

    /** 事件类型（如 "CACHE_INVALIDATION", "WORKFLOW_TASK_CREATED"） */
    private String eventType;

    /** 事件负载（JSONB 格式） */
    private String payload;

    /** 事件状态：PENDING / SENT / FAILED */
    private String status;

    /** 当前重试次数 */
    private Integer retryCount;

    /** 最大重试次数 */
    private Integer maxRetry;

    /** 下次重试时间（指数退避计算） */
    private LocalDateTime nextRetryTime;

    /** 发送成功时间 */
    private LocalDateTime sentTime;

    /** 错误信息（发送失败时记录） */
    private String errorMessage;
}
