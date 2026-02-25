---
phase: 25
title: "System Monitor API Rate Limit and WebSocket"
targets:
  backend: true
  frontend: true
depends_on: [24]
bundle_with: []
scope:
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

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Monitor 路由
- `spec/01-constraints.md` — §DAG 依赖
- `spec/08-output-rules.md`

## 任务

### 1. 系统监控

MonitorController（`/api/v1/monitor`）：

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | /api/v1/monitor/server | `system:monitor:server` | CPU、内存、磁盘信息 |
| GET | /api/v1/monitor/jvm | `system:monitor:jvm` | JVM 堆内存、GC 信息 |
| GET | /api/v1/monitor/cache | `system:monitor:cache` | Caffeine 缓存统计 |

使用 `java.lang.management.ManagementFactory` 获取 JVM 信息，`java.io.File` 获取磁盘信息，无需额外依赖。

### 2. API 限流

`@RateLimit` 注解（在 web 模块）��
```java
@RateLimit(key = "user:{userId}", limit = 100, window = 60) // 每分钟 100 次
```

RateLimitInterceptor 基于 Caffeine 实现令牌桶，按 key 限流。key 支持 SpEL 表达式（`{userId}` 从 SecurityContext 提取）。

### 3. WebSocket 实时通知

WebSocketConfig：启用 Spring WebSocket，端点 `/ws/notifications`，允许跨域。

NotificationWebSocketHandler：
- 连接时验证 JWT（从 query param `token` 提取）
- 维护 userId → WebSocketSession 映射
- 提供 `sendToUser(userId, message)` 方法供其他 Service 调用

### 前端

- `src/api/monitor.ts` — 调用监控接口
- `src/views/monitor/server/index.vue` — 服务器信息 Dashboard（进度条展示 CPU/内存使用率）
- `src/composables/useWebSocket.ts` — WebSocket 连接管理，自动重连，接收通知

## 关键约束

- RateLimitInterceptor 在 web 模块，可 import security 包（DAG 合规：web 依赖 security）
- WebSocket 端点加入 SecurityConfig 白名单（`/ws/**`）
- 无新增数据库迁移

## Phase-Local Manifest

```
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/MonitorController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/ServerInfoVO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/JvmInfoVO.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/annotation/RateLimit.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/interceptor/RateLimitInterceptor.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/config/WebSocketConfig.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/websocket/NotificationWebSocketHandler.java
ljwx-platform-admin/src/api/monitor.ts
ljwx-platform-admin/src/views/monitor/server/index.vue
ljwx-platform-admin/src/composables/useWebSocket.ts
```

## 验收条件

1. MonitorController 所有方法有 @PreAuthorize
2. RateLimitInterceptor 无 data 模块 import（DAG 合规）
3. WebSocket 端点在 SecurityConfig 白名单中
4. 编译通过，type-check 通过

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
