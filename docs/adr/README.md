# ADR 索引

本目录包含 LJWX Platform 的架构决策记录 (Architecture Decision Records)。

## ADR 列表

| 编号 | 标题 | 状态 | 相关 Phase |
|------|------|------|-----------|
| [ADR-0001](./ADR-0001-multi-level-cache.md) | 多副本下缓存一致性采用 Caffeine L1 + Redis L2 + Pub/Sub 失效广播 | Accepted | Phase 33 |
| [ADR-0002](./ADR-0002-redis-only-for-security.md) | Token 黑名单与在线用户状态采用 Redis Only | Accepted | Phase 22 |
| [ADR-0003](./ADR-0003-prometheus-low-cardinality.md) | Prometheus 指标维度坚持低基数；租户维度用日志/落库实现 | Accepted | Phase 35, 36 |
| [ADR-0004](./ADR-0004-outbox-pattern.md) | 涉及"写库 + 外部动作"的一致性采用 Outbox Pattern | Accepted | Phase 34, 28 |
| [ADR-0005](./ADR-0005-outbox-notify-polling.md) | Outbox 投递采用 "NOTIFY 触发 + 轮询兜底" | Accepted | Phase 34, 28 |
| [ADR-0006](./ADR-0006-hmac-authentication.md) | 开放平台认证采用 HMAC + timestamp + nonce 防重放 + 密钥轮换 | Accepted | Phase 29 |
| [ADR-0007](./ADR-0007-open-api-tenant-binding.md) | 开放 API 的 tenantId 以 open_app 绑定为准，忽略客户端声明 | Accepted | Phase 29 |
| [ADR-0008](./ADR-0008-workflow-visibility.md) | 工作流实例可见性采用 6 级模型（含可选部门范围管理） | Accepted | Phase 26 |
| [ADR-0009](./ADR-0009-dept-leader-user-id.md) | 部门负责人采用 `leader_user_id` 主语义，`sys_dept_leader` 为可选扩展 | Accepted | Phase 40 |
| [ADR-0010](./ADR-0010-data-masking.md) | 脱敏在序列化层实现，解脱敏受权限控制 | Accepted | Phase 39 |

## ADR 模板

每个 ADR 包含以下部分:

- **Status**: 决策状态 (Proposed/Accepted/Deprecated/Superseded)
- **Context**: 背景和问题描述
- **Decision**: 决策内容和实现方案
- **Consequences**: 影响和后果 (正面/负面)
- **References**: 相关文档和 Phase

## 如何使用

1. **查阅决策**: 按编号或标题查找相关 ADR
2. **新增决策**: 复制模板,按顺序编号,提交 PR
3. **更新决策**: 如果决策被废弃或替代,更新 Status 并说明原因

## 相关文档

- [Phase Spec 目录](../../spec/phase/)
- [全局约束](../../spec/01-constraints.md)
- [P0-P1 Spec 索引](../P0-P1-Spec-Index.md)
