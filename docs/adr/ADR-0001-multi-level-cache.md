# ADR-0001: 多副本下缓存一致性采用 Caffeine L1 + Redis L2 + Pub/Sub 失效广播

## Status
Accepted

## Context
平台生产环境采用 2+ replicas（K8s Deployment），仅本地 Caffeine 会导致权限、品牌、域名映射、黑名单等在不同 Pod 间不一致。

在多副本部署场景下,如果仅使用本地缓存 (Caffeine),会出现以下问题:
- Pod A 更新了权限配置,但 Pod B 的缓存仍然是旧数据
- 用户在 Pod A 被强制下线,但请求路由到 Pod B 时仍然可以访问
- 品牌配置更新后,不同 Pod 显示不一致的 UI

这些问题会导致严重的安全隐患和用户体验问题。

## Decision
采用**两级缓存**架构:
1. **Caffeine (L1)**: 本地缓存,提供极低延迟访问
2. **Redis (L2)**: 分布式缓存,保证多副本数据一致性
3. **Redis Pub/Sub**: 广播 `cache.evict` 事件,清理各 Pod L1 缓存

### 缓存分档策略

| 档位 | L1 (Caffeine) | L2 (Redis) | 一致性 | 适用场景 |
|------|---------------|------------|--------|----------|
| **REDIS_ONLY** | ❌ | ✅ | 强一致 | 权限、菜单、黑名单、在线用户 |
| **CAFFEINE_REDIS** | ✅ (TTL 60s) | ✅ | 最终一致 | 字典、配置、品牌、域名映射 |
| **CAFFEINE_ONLY** | ✅ (TTL 300s) | ❌ | 本地一致 | 静态数据、枚举 |

### 失效广播机制
- 缓存更新时,通过 Redis Pub/Sub 广播失效事件
- 各 Pod 监听失效事件,清理本地 L1 缓存
- 失效事件包含: cacheName, cacheKey, eventType, sourcePod

## Consequences

### 正面影响
- 多副本部署时缓存一致性得到保证
- 关键安全数据 (黑名单/在线用户) 使用 Redis Only,保证强一致性
- 字典/配置等数据使用两级缓存,兼顾性能和一致性

### 负面影响
- 需要引入 Redis Sentinel/Cluster 运维能力与 readiness 检查
- Pub/Sub 不能保证离线可达,需依赖 TTL 兜底（最终一致）
- 对强一致类数据改为 Redis Only,增加 Redis 依赖

### 运维要求
- Redis 高可用部署 (Sentinel 或 Cluster)
- 监控 Redis 连接状态和 Pub/Sub 延迟
- 配置 Redis 不可用时的降级策略

## References
- Phase 33: 多级缓存管理器
- spec/phase/phase-33.md
