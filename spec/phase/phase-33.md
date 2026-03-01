---
phase: 33
title: "多级缓存管理器 (Multi-Level Cache Manager)"
targets:
  backend: true
  frontend: false
depends_on: [32]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V033__create_cache_invalidation_event.sql"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/cache/MultiLevelCacheManager.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/cache/CacheLevel.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/cache/CacheInvalidationListener.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/cache/config/CacheConfig.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/cache/annotation/Cacheable.java"
  - "ljwx-platform-app/src/main/resources/application.yml"
---
# Phase 33 — 多级缓存管理器 (Multi-Level Cache Manager)

| 项目 | 值 |
|-----|---|
| Phase | 33 |
| 模块 | ljwx-platform-core (后端) |
| Feature | L0-D01-F01, L0-D01-F02 |
| 前置依赖 | Phase 32 (Final Gate v3) |
| 测试契约 | `spec/tests/phase-33-cache.tests.yml` |
| 优先级 | 🔴 **P0 - 生产就绪必需** |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §缓存失效事件表
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前系统仅使用 Caffeine 本地缓存,多 Pod 部署时存在缓存不一致问题,导致权限、菜单、数据范围等关键数据可能不同步。

**解决方案**: 实现 Caffeine L1 + Redis L2 + Pub/Sub 广播的多级缓存架构,支持三档缓存策略:
- **Redis Only**: 强一致性场景(权限、菜单)
- **Caffeine + Redis**: 最终一致性场景(字典、配置)
- **Caffeine Only**: 本地缓存场景(静态数据)

---

## 数据库契约

### 表结构：cache_invalidation_event

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| cache_name | VARCHAR(100) | NOT NULL, INDEX | 缓存名称 |
| cache_key | VARCHAR(500) | NOT NULL | 缓存键 |
| event_type | VARCHAR(20) | NOT NULL | EVICT / CLEAR |
| source_pod | VARCHAR(100) | NOT NULL | 发起 Pod 标识 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `idx_cache_name_created_time` (cache_name, created_time DESC)
- `idx_tenant_id` (tenant_id)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V033__create_cache_invalidation_event.sql` | 建表 + 索引 + 分区（按月） |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## 架构设计

### 缓存层级

```
┌─────────────────────────────────────────┐
│  Application Layer                      │
│  @Cacheable(level=REDIS_ONLY)          │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  MultiLevelCacheManager                 │
│  ┌─────────────┐  ┌──────────────────┐ │
│  │ Caffeine L1 │  │ Redis L2         │ │
│  │ (本地缓存)   │  │ (分布式缓存)      │ │
│  └─────────────┘  └──────────────────┘ │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  Redis Pub/Sub                          │
│  Channel: cache:invalidation            │
│  Payload: {cacheName, key, eventType}   │
└─────────────────────────────────────────┘
```

### 缓存分档策略

| 档位 | 适用场景 | L1 (Caffeine) | L2 (Redis) | 一致性 |
|------|----------|---------------|------------|--------|
| **REDIS_ONLY** | 权限、菜单、数据范围 | ❌ | ✅ | 强一致 |
| **CAFFEINE_REDIS** | 字典、配置、租户信息 | ✅ (TTL 60s) | ✅ | 最终一致 |
| **CAFFEINE_ONLY** | 静态数据、枚举 | ✅ (TTL 300s) | ❌ | 本地一致 |

---

## 核心组件契约

### CacheLevel 枚举

```java
public enum CacheLevel {
    REDIS_ONLY,        // 仅 Redis,强一致性
    CAFFEINE_REDIS,    // Caffeine + Redis,最终一致性
    CAFFEINE_ONLY      // 仅 Caffeine,本地缓存
}
```

### @Cacheable 注解

```java
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface Cacheable {
    String cacheName();                    // 缓存名称
    String key() default "";               // SpEL 表达式
    CacheLevel level() default CAFFEINE_REDIS;  // 缓存档位
    long ttl() default 300;                // TTL (秒)
    boolean sync() default false;          // 是否同步加载
}
```

### MultiLevelCacheManager

```java
public class MultiLevelCacheManager {

    // 获取缓存值
    <T> T get(String cacheName, String key, CacheLevel level);

    // 设置缓存值
    void put(String cacheName, String key, Object value, CacheLevel level, long ttl);

    // 失效单个缓存
    void evict(String cacheName, String key, CacheLevel level);

    // 清空缓存
    void clear(String cacheName, CacheLevel level);

    // 广播失效事件
    void broadcastInvalidation(String cacheName, String key, String eventType);
}
```

---

## 业务规则

> 格式：BL-33-{序号}：[条件] → [动作] → [结果/异常]

- **BL-33-01**：`REDIS_ONLY` 档位 → 直接读写 Redis → 不使用 Caffeine L1
- **BL-33-02**：`CAFFEINE_REDIS` 档位 → 先查 Caffeine L1,未命中则查 Redis L2 → 命中后回填 L1
- **BL-33-03**：`CAFFEINE_ONLY` 档位 → 仅使用 Caffeine L1 → 不使用 Redis L2
- **BL-33-04**：缓存失效时 → 广播 Pub/Sub 消息 → 所有 Pod 失效本地缓存
- **BL-33-05**：收到 Pub/Sub 消息 → 检查 sourcePod → 跳过自己发出的消息
- **BL-33-06**：权限缓存 → 使用 `REDIS_ONLY` → 保证强一致性
- **BL-33-07**：字典缓存 → 使用 `CAFFEINE_REDIS` + TTL 60s → 最终一致性
- **BL-33-08**：Caffeine L1 最大容量 → 10000 条 → 超出后 LRU 淘汰
- **BL-33-09**：Redis L2 TTL → 默认 300s → 可通过注解自定义

---

## 配置契约

### application.yml

```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}
      database: 0
      lettuce:
        pool:
          max-active: 8
          max-idle: 8
          min-idle: 2
          max-wait: 1000ms
      timeout: 3000ms

cache:
  caffeine:
    max-size: 10000
    expire-after-write: 300s
  redis:
    key-prefix: "ljwx:cache:"
    default-ttl: 300
  pubsub:
    channel: "cache:invalidation"
```

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-33-cache.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-33-01 | REDIS_ONLY 档位读写 | P0 |
| TC-33-02 | CAFFEINE_REDIS 档位 L1 命中 | P0 |
| TC-33-03 | CAFFEINE_REDIS 档位 L1 未命中,L2 命中 | P0 |
| TC-33-04 | CAFFEINE_ONLY 档位读写 | P0 |
| TC-33-05 | 缓存失效 Pub/Sub 广播 | P0 |
| TC-33-06 | 多 Pod 缓存一致性 | P0 |
| TC-33-07 | 权限缓存强一致性 | P0 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：MultiLevelCacheManager 支持三档缓存策略
- **AC-03**：Redis Pub/Sub 广播缓存失效事件
- **AC-04**：CacheInvalidationListener 正确处理失效消息
- **AC-05**：权限缓存使用 `REDIS_ONLY`,保证强一致性
- **AC-06**：字典缓存使用 `CAFFEINE_REDIS`,TTL 60s
- **AC-07**：多 Pod 部署时缓存一致性测试通过
- **AC-08**：编译通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 权限缓存：必须使用 `REDIS_ONLY`,保证强一致性
- Pub/Sub 消息：必须包含 sourcePod,避免循环广播
- Caffeine L1：最大容量 10000,LRU 淘汰
- Redis L2：默认 TTL 300s,可通过注解自定义
- 禁止：在 DTO 中声明 `tenantId`
