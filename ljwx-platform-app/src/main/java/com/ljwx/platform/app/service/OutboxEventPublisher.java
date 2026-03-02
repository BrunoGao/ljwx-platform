package com.ljwx.platform.app.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ljwx.platform.app.infra.mapper.OutboxEventMapper;
import com.ljwx.platform.core.event.OutboxEvent;
import com.ljwx.platform.core.id.SnowflakeIdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Outbox 事件发布器。
 *
 * <p>在业务事务中调用 {@link #publish} 方法，将事件写入 sys_outbox_event 表。
 * 后台轮询器（OutboxEventPoller）定期扫描 PENDING 事件并发送。
 *
 * <p>使用示例：
 * <pre>
 * &#64;Transactional
 * public void updateUser(Long userId, UserUpdateDTO dto) {
 *     userMapper.updateById(user);
 *     outboxEventPublisher.publish("User", userId, "CACHE_INVALIDATION", dto);
 * }
 * </pre>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OutboxEventPublisher {

    private final OutboxEventMapper outboxEventMapper;
    private final ObjectMapper objectMapper;
    private final SnowflakeIdGenerator idGenerator;

    /**
     * 发布事件（默认最大重试 3 次）。
     *
     * @param aggregateType 聚合根类型
     * @param aggregateId   聚合根 ID
     * @param eventType     事件类型
     * @param payload       事件负载
     */
    public void publish(String aggregateType, Long aggregateId, String eventType, Object payload) {
        publish(aggregateType, aggregateId, eventType, payload, 3);
    }

    /**
     * 发布事件（指���最大重试次数）。
     *
     * @param aggregateType 聚合根类型
     * @param aggregateId   聚合根 ID
     * @param eventType     事件类型
     * @param payload       事件负载
     * @param maxRetry      最大重试次数
     */
    public void publish(String aggregateType, Long aggregateId, String eventType, Object payload, int maxRetry) {
        try {
            OutboxEvent event = new OutboxEvent();
            event.setId(idGenerator.nextId());
            event.setAggregateType(aggregateType);
            event.setAggregateId(aggregateId);
            event.setEventType(eventType);
            event.setPayload(objectMapper.writeValueAsString(payload));
            event.setStatus("PENDING");
            event.setRetryCount(0);
            event.setMaxRetry(maxRetry);
            event.setNextRetryTime(LocalDateTime.now());

            outboxEventMapper.insert(event);
            log.debug("Outbox event published: type={}, aggregateType={}, aggregateId={}",
                    eventType, aggregateType, aggregateId);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize payload for outbox event: type={}, aggregateType={}, aggregateId={}",
                    eventType, aggregateType, aggregateId, e);
            throw new RuntimeException("Failed to publish outbox event", e);
        }
    }
}
