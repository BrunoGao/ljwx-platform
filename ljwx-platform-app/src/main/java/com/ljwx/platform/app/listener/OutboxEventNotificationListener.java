package com.ljwx.platform.app.listener;

import com.ljwx.platform.app.infra.mapper.OutboxEventMapper;
import com.ljwx.platform.core.event.OutboxEvent;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDateTime;

/**
 * PostgreSQL LISTEN/NOTIFY 监听器。
 *
 * <p>监听 outbox_event_channel 通道，当新事件插入时实时处理。
 * 配合 OutboxEventPoller 实现双重保障：
 * <ul>
 *   <li>NOTIFY 触发实时处理（低延迟）</li>
 *   <li>定时轮询兜底（高可靠）</li>
 * </ul>
 *
 * <p>触发器定义见 V034__create_outbox_event.sql。
 *
 * <p>配置：
 * <pre>
 *   outbox.notify.enabled: true  # 默认 false
 * </pre>
 *
 * <p><strong>注意</strong>：此功能需要 PostgreSQL JDBC 驱动在编译时可用。
 * 由于 pom.xml 中 postgresql 依赖为 runtime scope，此类使用反射调用 PGConnection API。
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "outbox.notify.enabled", havingValue = "true", matchIfMissing = false)
public class OutboxEventNotificationListener {

    private final DataSource dataSource;
    private final OutboxEventMapper outboxEventMapper;
    private final ApplicationEventPublisher applicationEventPublisher;

    private Connection listenerConnection;
    private Thread listenerThread;
    private volatile boolean running = false;

    /**
     * 启动 PostgreSQL NOTIFY 监听器。
     */
    @PostConstruct
    public void startListening() {
        try {
            listenerConnection = dataSource.getConnection();

            // 使用反射调用 PGConnection.unwrap() 避免编译时依赖
            Object pgConnection = listenerConnection.unwrap(
                    Class.forName("org.postgresql.PGConnection"));

            // 订阅 outbox_event_channel
            try (Statement stmt = listenerConnection.createStatement()) {
                stmt.execute("LISTEN outbox_event_channel");
            }

            running = true;
            listenerThread = new Thread(() -> {
                log.info("PostgreSQL NOTIFY listener started for outbox_event_channel");
                while (running) {
                    try {
                        // 调用 pgConnection.getNotifications(10000)
                        Object[] notifications = (Object[]) pgConnection.getClass()
                                .getMethod("getNotifications", int.class)
                                .invoke(pgConnection, 10000);

                        if (notifications != null) {
                            for (Object notification : notifications) {
                                handleNotification(notification);
                            }
                        }
                    } catch (Exception e) {
                        if (running) {
                            log.error("Error while listening for PostgreSQL notifications", e);
                        }
                    }
                }
                log.info("PostgreSQL NOTIFY listener stopped");
            });
            listenerThread.setName("outbox-notify-listener");
            listenerThread.setDaemon(true);
            listenerThread.start();

        } catch (Exception e) {
            log.error("Failed to start PostgreSQL NOTIFY listener. " +
                    "Ensure PostgreSQL JDBC driver is available and outbox.notify.enabled=true", e);
        }
    }

    /**
     * 停止监听器。
     */
    @PreDestroy
    public void stopListening() {
        running = false;
        if (listenerThread != null) {
            listenerThread.interrupt();
        }
        if (listenerConnection != null) {
            try {
                listenerConnection.close();
            } catch (SQLException e) {
                log.error("Failed to close listener connection", e);
            }
        }
    }

    /**
     * 处理 PostgreSQL NOTIFY 通知（使用反射）。
     *
     * @param notification PGNotification 对象
     */
    private void handleNotification(Object notification) {
        try {
            // 调用 notification.getName() 和 notification.getParameter()
            Class<?> notificationClass = notification.getClass();
            String channel = (String) notificationClass.getMethod("getName").invoke(notification);
            String parameter = (String) notificationClass.getMethod("getParameter").invoke(notification);

            if (!"outbox_event_channel".equals(channel)) {
                return;
            }

            Long eventId = Long.parseLong(parameter);
            processEvent(eventId);

        } catch (Exception e) {
            log.error("Failed to handle PostgreSQL notification: {}", notification, e);
        }
    }

    /**
     * 处理单个事件。
     *
     * @param eventId 事件 ID
     */
    private void processEvent(Long eventId) {
        try {
            OutboxEvent event = outboxEventMapper.selectById(eventId);
            if (event == null) {
                log.warn("Outbox event not found: id={}", eventId);
                return;
            }

            if (!"PENDING".equals(event.getStatus())) {
                log.debug("Outbox event already processed: id={}, status={}", eventId, event.getStatus());
                return;
            }

            // 发布到 ApplicationEventBus
            applicationEventPublisher.publishEvent(event);

            // 标记为已发送
            outboxEventMapper.markAsSent(event.getId(), LocalDateTime.now());

            log.info("Outbox event sent via NOTIFY: id={}, type={}, aggregateType={}, aggregateId={}",
                    event.getId(), event.getEventType(), event.getAggregateType(), event.getAggregateId());

        } catch (Exception e) {
            log.error("Failed to process outbox event via NOTIFY: id={}", eventId, e);
            // 失败不重试，由 OutboxEventPoller 兜底
        }
    }
}
