# ADR-0004: 涉及"写库 + 外部动作"的一致性采用 Outbox Pattern

## Status
Accepted

## Context
业务事务成功但消息/Webhook/广播失败会产生不可追溯、不一致与重复发送问题。

在分布式系统中,常见的问题场景:
1. **事务成功,消息丢失**: 用户创建成功,但欢迎邮件未发送
2. **事务失败,消息已发**: 订单创建失败,但库存已扣减
3. **重复发送**: 网络超时重试,导致消息重复发送
4. **不可追溯**: 消息发送失败,无法查询和重试

传统的"先写库,再发消息"方案无法保证一致性:
```java
// 反模式: 不可靠
@Transactional
public void createUser(User user) {
    userRepository.save(user);  // 事务内
    emailService.send(user);     // 事务外,可能失败
}
```

## Decision
所有需要外部副作用的动作（消息发送、Webhook 推送、缓存失效广播等）通过**事务内写 `sys_outbox_event`**，由异步投递器可靠处理与重试。

### Outbox Pattern 流程
1. **事务内写 Outbox**: 业务操作和 Outbox 事件在同一事务中
2. **异步投递**: 独立的投递器扫描 PENDING 事件并投递
3. **幂等处理**: 投递器保证幂等,避免重复发送
4. **重试机制**: 失败自动重试,支持指数退避
5. **死信告警**: 超过最大重试次数后告警

### 实现示例
```java
@Transactional
public void createUser(User user) {
    // 1. 写业务表
    userRepository.save(user);

    // 2. 写 Outbox 事件 (同一事务)
    OutboxEvent event = OutboxEvent.builder()
        .eventType("USER_CREATED")
        .aggregateId(user.getId())
        .payload(toJson(user))
        .status(OutboxStatus.PENDING)
        .build();
    outboxRepository.save(event);

    // 3. 事务提交后,投递器异步处理
}
```

### 适用场景
- 消息发送 (Email/SMS/WebSocket)
- Webhook 推送
- 缓存失效广播
- 事件总线发布
- 第三方 API 调用

## Consequences

### 正面影响
- 保证业务操作和外部动作的最终一致性
- 所有外部动作可追溯、可重试、可监控
- 避免消息丢失和重复发送

### 负面影响
- 需要实现 Outbox 投递服务、重试、死信告警、清理策略
- 业务代码不直接"发消息",而是写事件 (需要适应)
- 增加数据库写入量 (每个外部动作都写 Outbox)

### 实施要点
1. **投递器**: 独立的后台服务,扫描 PENDING 事件并投递
2. **幂等性**: 投递器必须保证幂等,避免重复发送
3. **重试策略**: 指数退避 (1min, 5min, 30min, 2h, 6h)
4. **死信处理**: 超过最大重试次数后,标记为 FAILED 并告警
5. **清理策略**: 定期清理已完成的 Outbox 事件 (保留 7 天)

## References
- Phase 34: Outbox 事件表
- Phase 28: Outbox 消费框架
- spec/phase/phase-34.md
