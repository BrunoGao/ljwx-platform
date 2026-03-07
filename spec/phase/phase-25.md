---
phase: 25
title: "System Monitor API Rate Limit and WebSocket"
targets:
  backend: true
  frontend: true
depends_on: [24]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V029__seed_phase26_permissions.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/MonitorController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/ServerInfoVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/JvmInfoVO.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/annotation/RateLimit.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/interceptor/RateLimitInterceptor.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/config/WebSocketConfig.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/websocket/NotificationWebSocketHandler.java"
  - "ljwx-platform-admin/src/api/monitor.ts"
  - "ljwx-platform-admin/src/views/monitor/server/index.vue"
  - "ljwx-platform-admin/src/composables/useWebSocket.ts"
---
# Phase 25: System Monitor, Rate Limit & WebSocket

## Overview

| 属性 | 值 |
|------|-----|
| Phase | 25 |
| 模块 | ljwx-platform-app（Monitor + WebSocket）、ljwx-platform-web（RateLimit 注解）、ljwx-platform-admin（前端） |
| Feature | 系统监控 REST 端点 / @RateLimit 注解 + 拦截器 / WebSocket 实时通知 |
| 前置依赖 | Phase 24 |
| 测试契约 | [spec/tests/phase-25-monitor.tests.yml](../tests/phase-25-monitor.tests.yml) |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Monitor 路由
- `spec/04-database.md` — V029 权限种子
- `spec/01-constraints.md` — §DAG 依赖
- `spec/08-output-rules.md`

## Flyway 契约

| 文件 | 说明 |
|------|------|
| `V029__seed_phase26_permissions.sql` | 补齐 Phase 21-25 相关权限种子并赋权给 admin（dept / monitor / online / login-log / tenant-package / user import-export / notice read） |

## API 契约

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/monitor/server | `system:monitor:server` | CPU、内存、磁盘信息（ManagementFactory + java.io.File） |
| GET | /api/v1/monitor/jvm | `system:monitor:jvm` | JVM 堆内存、GC 信息（ManagementFactory） |
| GET | /api/v1/monitor/cache | `system:monitor:cache` | Caffeine 缓存统计 |

## 组件契约

### @RateLimit 注解（web 模块）

`@RateLimit` 注解三个属性：`key`（SpEL 表达式，`{userId}` 从 SecurityContext 提取）、`limit`（窗口内最大请求数）、`window`（窗口秒数）。

### RateLimitInterceptor（web 模块）

基于 Caffeine 实现令牌桶，解析 key 后按用户维度限流，超限返回 HTTP 429，body 错误码 `RATE_LIMIT_EXCEEDED`。

### WebSocket（app 模块）

| 属性 | 值 |
|------|-----|
| 端点 | `/ws/notifications` |
| 认证方式 | query param `token`，握手时校验 JWT |
| 会话管理 | ConcurrentHashMap 维护 `userId → WebSocketSession` |
| 核心方法 | `sendToUser(userId, message)` 供其他 Service 调用 |

### 前端文件

| 文件 | 说明 |
|------|------|
| `src/api/monitor.ts` | 调用三个监控接口，返回类型来自 `@ljwx/shared` |
| `src/views/monitor/server/index.vue` | 服务器 Dashboard，进度条展示 CPU / 内存使用率 |
| `src/composables/useWebSocket.ts` | WebSocket 连接管理，自动重连，接收通知后通过回调暴露 |

## 业务规则

| 规则 | 条件 → 结果 |
|------|-------------|
| BL-25-01 | RateLimitInterceptor 解析 key 后查 Caffeine 令牌桶 → 剩余令牌 > 0 则放行并扣减；否则返回 429 |
| BL-25-02 | WS 连接建立时 → 从 query param `token` 提取 JWT 并校验，失败则关闭连接（CloseStatus.NOT_ACCEPTABLE） |
| BL-25-03 | WS 连接成功 → 将 userId 与 WebSocketSession 存入 ConcurrentHashMap；断开时移除对应条目 |
| BL-25-04 | 请求超过 limit/window 阈值 → HTTP 429，body `{"code":"RATE_LIMIT_EXCEEDED","msg":"请求过于频繁"}` |

## P0 测试摘要

| TC ID | 端点 | 场景 | 预期 |
|-------|------|------|------|
| TC-25-01 | GET /api/v1/monitor/server | 无 token | 401 |
| TC-25-02 | GET /api/v1/monitor/server | 缺权限（无 system:monitor:server）| 403 |
| TC-25-03 | GET /api/v1/monitor/server | 正常请求 | 200，data 非空 |
| TC-25-04 | GET /api/v1/monitor/jvm | 正常请求 | 200，data.heapUsed 为数字 |
| TC-25-05 | GET /api/v1/monitor/cache | 正常请求 | 200 |
| TC-25-06 | 加 @RateLimit 端点（连续超限） | 超出 limit/window | 429，code=RATE_LIMIT_EXCEEDED |

完整测试用例见 [spec/tests/phase-25-monitor.tests.yml](../tests/phase-25-monitor.tests.yml)。

## 关键约束

- RateLimitInterceptor 位于 web 模块，可 import security 包（DAG 合规：web 依赖 security）
- RateLimitInterceptor 禁止 import data 模块任何类（DAG 合规）
- WebSocket 端点 `/ws/**` 加入 SecurityConfig 白名单
- 监控数据采集仅用 `java.lang.management.ManagementFactory` 与 `java.io.File`，无额外依赖
- 包含 V029 权限种子迁移，禁止 `IF NOT EXISTS`

## 验收条件

1. MonitorController 三个方法均有 `@PreAuthorize`
2. RateLimitInterceptor 无 data 模块 import（DAG 合规）
3. WebSocket 端点 `/ws/**` 在 SecurityConfig 白名单中
4. V029 权限种子迁移已纳入并通过校验
5. 编译通过，type-check 通过

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-25-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-25-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-25-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-25-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-25-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-25-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-25-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-25-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-25-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-25-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
