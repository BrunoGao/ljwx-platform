# ADR-0003: Prometheus 指标维度坚持低基数；租户维度用日志/落库实现

## Status
Accepted

## Context
tenantId/userId/原始 uri 作为 label 会造成 Prometheus TSDB 高基数爆炸。

Prometheus 使用时间序列数据库 (TSDB),每个唯一的 label 组合都会创建一个新的时间序列。如果使用高基数维度 (如 tenantId, userId, 原始 URI) 作为 label:
- 100 个租户 × 1000 个用户 × 100 个 URI = 1000 万个时间序列
- Prometheus 内存占用爆炸,查询性能急剧下降
- 最终导致 Prometheus 不可用

## Decision
Prometheus 仅允许低基数维度（app/env/method/status/routeTemplate 等）；租户维度统计通过以下方式实现:

### 1. Loki 日志聚合（字段级,不做 label）
- 租户请求量、错误率等通过 Loki 日志查询
- traceId/tenantId/userId 作为 JSON 字段,不做 label
- Loki label 仅保留: app, env, level

### 2. PostgreSQL 聚合表（运营/计量）
- 租户用量统计: `bill_usage_record`
- 租户运营数据: DAU/MAU, 存储用量, API 调用量
- 通过定时任务聚合,存储到数据库

### 低基数维度示例
允许的 Prometheus label:
- `app`: 应用名称 (ljwx-platform)
- `env`: 环境 (dev/test/prod)
- `method`: HTTP 方法 (GET/POST/PUT/DELETE)
- `status`: HTTP 状态码 (200/400/500)
- `routeTemplate`: 路由模板 (/api/v1/users/{id})

禁止的 Prometheus label:
- `tenantId`: 租户 ID (高基数)
- `userId`: 用户 ID (高基数)
- `uri`: 原始 URI (高基数)
- `traceId`: 链路追踪 ID (高基数)

## Consequences

### 正面影响
- Prometheus 保持低基数,性能稳定
- 租户维度数据通过 Loki/PostgreSQL 实现,更灵活

### 负面影响
- 租户运营看板的数据源更多来自 DB/Loki,而非 Prometheus
- 需要实现 Loki 日志聚合和 PostgreSQL 定时统计

### 实施要点
1. **Prometheus 指标**: 仅用于全局监控和告警
2. **Loki 日志**: 用于租户维度查询和排查
3. **PostgreSQL**: 用于租户运营数据和计费统计

## References
- Phase 35: 结构化日志与 Loki 集成
- Phase 36: Prometheus 指标监控
- spec/phase/phase-35.md
- spec/phase/phase-36.md
