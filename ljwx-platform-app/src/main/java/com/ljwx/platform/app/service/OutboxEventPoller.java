package com.ljwx.platform.app.service;

import com.ljwx.platform.app.infra.mapper.OutboxEventMapper;
import com.ljwx.platform.core.event.OutboxEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Outbox 事件轮询器。
 *
 * <p>定期扫描 sys_outbox_event 表中的 PENDING 事件，发布到 ApplicationEventBus。
 * 发送成功后更新状态为 SENT，失败则重试（指数退避）。
 *
 * <p>重试策略：
 * <pre>
 *   next_retry_time = now + 2^retry_count * 60s
 *   最大延迟：30 分钟
 * </pre>
 *
 * <p>配置：
 * <pre>
 *   outbox.poller.enabled: true
 *   outbox.poller.fixed-delay: 10000  # 10 秒
 *   outbox.poller.batch-size: 100
 * </pre>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OutboxEventPoller {

    private final OutboxEventMapper outboxEventMapper;
    private final ApplicationEventPublisher applicationEventPublisher;

    private static final int BATCH_SIZE = 100;
    private static final int MAX_DELAY_SECONDS = 1800; // 30 分钟

    /**
     * 定期轮询并发送事件（每 10 秒执行一次）。
     */
    @Scheduled(fixedDelay = 10000)
    @Transactional
    public void pollAndPublish() {
        try {
            LocalDateTime now = LocalDateTime.now();
            List<OutboxEvent> events = outboxEventMapper.selectPendingEvents(now, BATCH_SIZE);

            if (events.isEmpty()) {
                return;
            }

            log.debug("Found {} pending outbox events", events.size());

            for (OutboxEvent event : events) {
                processEvent(event);
            }
        } catch (Exception e) {
            log.error("Failed to poll and publish outbox events", e);
        }
    }

    /**
     * 处理单个事件。
     *
     * @param event 待处理事件
     */
    private void processEvent(OutboxEvent event) {
        try {
            // 发布到 ApplicationEventBus
            applicationEventPublisher.publishEvent(event);

            // 标记为已发送
            outboxEventMapper.markAsSent(event.getId(), LocalDateTime.now());

            log.info("Outbox event sent: id={}, type={}, aggregateType={}, aggregateId={}",
                    event.getId(), event.getEventType(), event.getAggregateType(), event.getAggregateId());
        } catch (Exception e) {
            log.error("Failed to process outbox event: id={}, type={}", event.getId(), event.getEventType(), e);
            retryFailedEvent(event, e.getMessage());
        }
    }

    /**
     * 重试失败事件（指数退避）。
     *
     * @param event        失败事件
     * @param errorMessage 错误信息
     */
    private void retryFailedEvent(OutboxEvent event, String errorMessage) {
        int newRetryCount = event.getRetryCount() + 1;

        if (newRetryCount >= event.getMaxRetry()) {
            // 达到最大重试次数，标记为 FAILED
            outboxEventMapper.markAsFailed(event.getId(), errorMessage);
            log.warn("Outbox event marked as FAILED after {} retries: id={}, type={}",
                    event.getMaxRetry(), event.getId(), event.getEventType());
        } else {
            // 计算下次重试时间（指数退避）
            int delaySeconds = (int) Math.pow(2, newRetryCount) * 60;
            delaySeconds = Math.min(delaySeconds, MAX_DELAY_SECONDS);
            LocalDateTime nextRetryTime = LocalDateTime.now().plusSeconds(delaySeconds);

            outboxEventMapper.incrementRetry(event.getId(), newRetryCount, nextRetryTime);
            log.info("Outbox event retry scheduled: id={}, retryCount={}, nextRetryTime={}",
                    event.getId(), newRetryCount, nextRetryTime);
        }
    }

    /**
     * 定期清理历史事件（每天凌晨 2 点执行）。
     * 删除 30 天前的 SENT 事件，保留 FAILED 事件。
     */
    @Scheduled(cron = "0 0 2 * * ?")
    @Transactional
    public void cleanupOldEvents() {
        try {
            LocalDateTime before = LocalDateTime.now().minusDays(30);
            int deleted = outboxEventMapper.deleteSentEventsBefore(before);
            log.info("Cleaned up {} old SENT outbox events before {}", deleted, before);
        } catch (Exception e) {
            log.error("Failed to cleanup old outbox events", e);
        }
    }
}
