---
phase: 34
title: "Outbox 事件表 (Outbox Event Pattern)"
targets:
  backend: true
  frontend: false
depends_on: [33]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V034__create_outbox_event.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/event/OutboxEvent.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/event/OutboxEventPublisher.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/service/OutboxEventPoller.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/OutboxEventMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/OutboxEventMapper.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/listener/OutboxEventNotificationListener.java"
---
# Phase 34 — Outbox 事件表 (Outbox Event Pattern)

| 项目 | 值 |
|-----|---|
| Phase | 34 |
| 模块 | ljwx-platform-core (后端) |
| Feature | L0-D05-F02 |
| 前置依赖 | Phase 33 (多级缓存) |
| 测试契约 | `spec/tests/phase-34-outbox.tests.yml` |
| 优先级 | 🔴 **P0 - 流程引擎前置依赖** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §Outbox 事件表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前系统无法保证"写库+发消息"的原子性,可能导致:
- 数据已写入,但消息未发送
- 消息已发送,但数据未写入
- 消息重复发送

**解决方案**: 实现 Outbox 事件表模式,保证事件最终一致性:
1. 业务事务中写入 Outbox 事件表
2. 后台轮询器定期扫描未发送事件
3. 发送成功后标记事件状态
4. 支持 PostgreSQL LISTEN/NOTIFY 实时推送

---

## 数据库契约

### 表结构：sys_outbox_event

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| aggregate_type | VARCHAR(100) | NOT NULL, INDEX | 聚合根类型 |
| aggregate_id | BIGINT | NOT NULL, INDEX | 聚合根 ID |
| event_type | VARCHAR(100) | NOT NULL | 事件类型 |
| payload | JSONB | NOT NULL | 事件负载 |
| status | VARCHAR(20) | NOT NULL, INDEX | PENDING / SENT / FAILED |
| retry_count | INT | NOT NULL, DEFAULT 0 | 重试次数 |
| max_retry | INT | NOT NULL, DEFAULT 3 | 最大重试次数 |
| next_retry_time | TIMESTAMP | INDEX | 下次重试时间 |
| sent_time | TIMESTAMP | | 发送成功时间 |
| error_message | TEXT | | 错误信息 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_status_next_retry_time` (status, next_retry_time) WHERE status = 'PENDING'
- `idx_aggregate` (aggregate_type, aggregate_id)
- `idx_tenant_id` (tenant_id)

**分区策略**: 按月分区 (created_time)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V034__create_outbox_event.sql` | 建表 + 索引 + 分区 + NOTIFY 触发器 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## 架构设计

### Outbox 模式流程

```
┌─────────────────────────────────────────┐
│  Business Transaction                   │
│  ┌─────────────┐  ┌──────────────────┐ │
│  │ Update Data │  │ Insert Outbox    │ │
│  │             │  │ Event (PENDING)  │ │
│  └─────────────┘  └──────────────────┘ │
│  COMMIT                                 │
└─────────────────┬───────────────────────┘
                  │
                  │ PostgreSQL NOTIFY
                  ▼
┌─────────────────────────────────────────┐
│  OutboxEventPoller (@Scheduled)         │
│  1. SELECT * FROM sys_outbox_event     │
│     WHERE status='PENDING'             │
│     AND next_retry_time <= NOW()       │
│  2. Publish to ApplicationEventBus     │
│  3. UPDATE status='SENT'               │
└─────────────────────────────────────────┘
```

### 事件类型

| 事件类型 | 说明 | 使用场景 |
|---------|------|----------|
| CACHE_INVALIDATION | 缓存失效 | 菜单、权限、数据范围变更 |
| WORKFLOW_TASK_CREATED | 流程任务创建 | 流程引擎 |
| WEBHOOK_TRIGGER | Webhook 触发 | 开放平台 |
| MESSAGE_SEND | 消息发送 | 消息中台 |

---

## 核心组件契约

### OutboxEvent 实体

```java
@Data
@TableName("sys_outbox_event")
public class OutboxEvent extends BaseEntity {
    private String aggregateType;
    private Long aggregateId;
    private String eventType;
    private String payload;  // JSONB
    private String status;   // PENDING / SENT / FAILED
    private Integer retryCount;
    private Integer maxRetry;
    private LocalDateTime nextRetryTime;
    private LocalDateTime sentTime;
    private String errorMessage;
}
```

### OutboxEventPublisher

```java
@Component
public class OutboxEventPublisher {

    // 发布事件（在业务事务中调用）
    public void publish(String aggregateType, Long aggregateId,
                       String eventType, Object payload);

    // 发布事件（指定最大重试次数）
    public void publish(String aggregateType, Long aggregateId,
                       String eventType, Object payload, int maxRetry);
}
```

### OutboxEventPoller

```java
@Component
public class OutboxEventPoller {

    // Quartz 定时任务（每 10 秒���行一次）
    @Scheduled(fixedDelay = 10000)
    public void pollAndPublish();

    // 处理单个事件
    private void processEvent(OutboxEvent event);

    // 重试失败事件
    private void retryFailedEvent(OutboxEvent event);
}
```

---

## 业务规则

> 格式：BL-34-{序号}：[条件] → [动作] → [结果/异常]

- **BL-34-01**：业务事务中 → 调用 `OutboxEventPublisher.publish()` → 插入 PENDING 事件
- **BL-34-02**：Outbox 事件插入成功 → 触发 PostgreSQL NOTIFY → 实时通知轮询器
- **BL-34-03**：轮询器扫描 PENDING 事件 → 发布到 ApplicationEventBus → 更新状态为 SENT
- **BL-34-04**：事件发送失败 → retry_count++ → 计算 next_retry_time（指数退避）
- **BL-34-05**：retry_count >= max_retry → 更新状态为 FAILED → 记录错误信息
- **BL-34-06**：指数退避策略 → `next_retry_time = now + 2^retry_count * 60s` → 最大 30 分钟
- **BL-34-07**：事件发送成功 → 更新 status='SENT', sent_time=NOW() → 不删除记录（审计）
- **BL-34-08**：定期清理 → 删除 30 天前的 SENT 事件 → 保留 FAILED 事件

---

## 配置契约

### application.yml

```yaml
outbox:
  poller:
    enabled: true
    fixed-delay: 10000  # 10 秒
    batch-size: 100
  retry:
    max-retry: 3
    initial-delay: 60   # 60 秒
    max-delay: 1800     # 30 分钟
  cleanup:
    enabled: true
    cron: "0 0 2 * * ?"  # 每天凌晨 2 点
    retention-days: 30
```

---

## PostgreSQL LISTEN/NOTIFY

### 触发器

```sql
CREATE OR REPLACE FUNCTION notify_outbox_event()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('outbox_event_channel', NEW.id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER outbox_event_notify
AFTER INSERT ON sys_outbox_event
FOR EACH ROW
EXECUTE FUNCTION notify_outbox_event();
```

### 监听器

```java
@Component
public class OutboxEventNotificationListener {

    @PostConstruct
    public void startListening() {
        // 监听 PostgreSQL NOTIFY
        pgConnection.addNotificationListener(notification -> {
            if ("outbox_event_channel".equals(notification.getName())) {
                Long eventId = Long.parseLong(notification.getParameter());
                processEvent(eventId);
            }
        });
    }
}
```

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-34-outbox.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-34-01 | 发布事件到 Outbox 表 | P0 |
| TC-34-02 | 轮询器扫描并发送事件 | P0 |
| TC-34-03 | 事件发送失败重试 | P0 |
| TC-34-04 | 达到最大重试次数标记 FAILED | P0 |
| TC-34-05 | 指数退避策略 | P0 |
| TC-34-06 | PostgreSQL NOTIFY 实时推送 | P1 |
| TC-34-07 | 定期清理历史事件 | P1 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：OutboxEventPublisher 在业务事务中插入事件
- **AC-03**：OutboxEventPoller 定期扫描并发送事件
- **AC-04**：事件发送失败自动重试,指数退避
- **AC-05**：达到最大重试次数标记为 FAILED
- **AC-06**：PostgreSQL NOTIFY 触发器正常工作
- **AC-07**：定期清理 30 天前的 SENT 事件
- **AC-08**：编译通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 事件发布：必须在业务事务中调用 `OutboxEventPublisher.publish()`
- 重试策略：指数退避,最大 30 分钟
- 事件清理：保留 30 天,FAILED 事件不删除
- 禁止：在 DTO 中声明 `tenantId`
