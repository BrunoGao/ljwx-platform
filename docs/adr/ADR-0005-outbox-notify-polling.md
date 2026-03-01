# ADR-0005: Outbox 投递采用 "NOTIFY 触发 + 轮询兜底"

## Status
Accepted

## Context
纯轮询延迟高；纯通知可能漏。

Outbox 投递器需要及时发现新事件并投递,有两种常见方案:

### 方案 1: 纯轮询
- 定时扫描 `sys_outbox_event` 表,查询 PENDING 事件
- 优点: 实现简单,不会漏事件
- 缺点: 延迟高 (轮询间隔),空轮询浪费资源

### 方案 2: 纯 NOTIFY
- 事务提交后发送 PostgreSQL NOTIFY 或应用内事件
- 优点: 延迟低,实时响应
- 缺点: 可能漏事件 (投递器重启、网络抖动)

两种方案都有明显缺陷,需要结合使用。

## Decision
DB 提交后 `NOTIFY` 触发投递器快速唤醒；同时定时轮询 PENDING 作为兜底。

### 实现方案

#### 1. NOTIFY 触发 (快速路径)
```java
@Transactional
public void createOutboxEvent(OutboxEvent event) {
    outboxRepository.save(event);
    // 事务提交后发送 NOTIFY
    jdbcTemplate.execute("NOTIFY outbox_event_channel");
}
```

投递器监听 NOTIFY:
```java
@Component
public class OutboxDispatcher {
    @PostConstruct
    public void startListening() {
        // 监听 PostgreSQL NOTIFY
        connection.createStatement()
            .execute("LISTEN outbox_event_channel");

        // 收到通知后立即扫描
        while (true) {
            PGNotification[] notifications = pgConnection.getNotifications();
            if (notifications != null) {
                dispatchPendingEvents();
            }
        }
    }
}
```

#### 2. 轮询兜底 (保底路径)
```java
@Scheduled(fixedDelay = 60000) // 每分钟
public void pollPendingEvents() {
    dispatchPendingEvents();
}
```

### 触发时机
- **NOTIFY**: 事务提交后立即触发,延迟 < 100ms
- **轮询**: 每 60 秒兜底,防止漏事件

## Consequences

### 正面影响
- 快速响应: NOTIFY 触发,延迟低
- 可靠性: 轮询兜底,不会漏事件
- 资源优化: 有事件时快速处理,无事件时低频轮询

### 负面影响
- 需要连接池支持 LISTEN/NOTIFY 或独立连接
- 实现幂等投递与并发控制（避免多实例重复发送）

### 实施要点

#### 1. NOTIFY 连接管理
- 使用独立的 JDBC 连接监听 NOTIFY (不占用连接池)
- 连接断开后自动重连并重新 LISTEN

#### 2. 并发控制
- 多实例部署时,使用行级锁或乐观锁避免重复投递
- 投递前先更新状态为 PROCESSING,投递成功后更新为 COMPLETED

```sql
-- 行级锁方案
SELECT * FROM sys_outbox_event
WHERE status = 'PENDING'
  AND next_retry_time <= NOW()
ORDER BY created_time
LIMIT 100
FOR UPDATE SKIP LOCKED;
```

#### 3. 幂等性保证
- 投递器记录 `last_processed_id`,避免重复处理
- 消息接收方实现幂等 (如 Email 去重、Webhook 签名校验)

## References
- Phase 34: Outbox 事件表
- Phase 28: Outbox 消费框架
- spec/phase/phase-34.md
