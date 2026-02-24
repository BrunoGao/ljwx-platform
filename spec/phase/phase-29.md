---
phase: 29
title: "Observability TraceId Structured Logging Slow API"
targets:
  backend: true
  frontend: true
depends_on: [28]
bundle_with: []
scope:
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/TraceIdFilter.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/aop/SlowApiAspect.java"
  - "ljwx-platform-app/src/main/resources/logback-spring.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/FrontendErrorController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/FrontendErrorDTO.java"
  - "ljwx-platform-app/src/main/resources/db/migration/V029__create_sys_frontend_error.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysFrontendError.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysFrontendErrorMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysFrontendErrorMapper.xml"
  - "ljwx-platform-admin/src/composables/useErrorMonitor.ts"
---
# Phase 29: Observability — TraceId / Structured Logging / Slow API

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §DAG 依赖
- `spec/04-database.md` — 审计字段规范
- `spec/08-output-rules.md`

## 任务

### 1. 请求链路追踪（web 模块）

**TraceIdFilter**：实现 `jakarta.servlet.Filter`，order=0（最高优先级，在 XssFilter 之前）：
- 从请求头 `X-Trace-Id` 读取 traceId，若无则生成（UUID 取前 16 位）
- 写入 `MDC.put("traceId", traceId)`
- 写入 `MDC.put("tenantId", ...)` 和 `MDC.put("userId", ...)`（从 SecurityContext 提取，未认证时为 "anonymous"）
- 响应头写入 `X-Trace-Id: {traceId}`
- finally 块清理 MDC（`MDC.clear()`）

### 2. 结构化日志（app 模块）

**logback-spring.xml**：替换默认控制台输出为 JSON 格式（使用 Logback 内置的 `JsonEncoder` 或 `PatternLayout` 输出 JSON 字符串）：

```xml
<encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
  <pattern>{"time":"%d{ISO8601}","level":"%level","traceId":"%X{traceId}","tenantId":"%X{tenantId}","userId":"%X{userId}","logger":"%logger{36}","msg":"%message"}%n</pattern>
</encoder>
```

生产环境（`application-prod.yml`）输出到文件，开发环境保持可读格式。

### 3. 慢接口监控（web 模块）

**SlowApiAspect**：AOP 切面，切点为所有 `@RestController` 方法：
- 记录方法执行时间
- 超过 3000ms 输出 WARN 日志，包含：接口路径、方法名、执行时间、traceId（从 MDC 读取）
- 超过 10000ms 输出 ERROR 日志

```java
@Aspect
@Component
public class SlowApiAspect {
    private static final long WARN_THRESHOLD_MS = 3000;
    private static final long ERROR_THRESHOLD_MS = 10000;
    // ...
}
```

### 4. 前端错误监控（后端接收端点）

**V029 表 sys_frontend_error**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| error_message | VARCHAR(1000) NOT NULL | 错误信息 |
| stack_trace | TEXT NOT NULL DEFAULT '' | 堆栈信息 |
| page_url | VARCHAR(500) NOT NULL DEFAULT '' | 发生页面 |
| user_agent | VARCHAR(500) NOT NULL DEFAULT '' | 浏览器信息 |
| + 7 列审计字段 | | |

**FrontendErrorController**：
```
POST /api/v1/frontend-errors  权限: 无需权限（已登录即可，@PreAuthorize("isAuthenticated()")）
```

**FrontendErrorDTO**：errorMessage、stackTrace、pageUrl、userAgent（均 @NotBlank）

### 5. 前端错误监控（前端上报）

**useErrorMonitor.ts**（admin 模块）：
```typescript
export function useErrorMonitor() {
  // 监听 window.onerror 和 unhandledrejection
  // 上报到 POST /api/v1/frontend-errors
  // 防抖：同一错误 5 秒内只上报一次
}
```

在 `main.ts` 中调用 `useErrorMonitor()` 初始化。

## 关键约束

- TraceIdFilter 在 web 模块，不依赖 security/data（DAG 合规）
- SlowApiAspect 在 web 模块，需要 spring-boot-starter-aop（已在 web pom.xml 中）
- V029 含 7 列审计字段，无 IF NOT EXISTS
- FrontendErrorController 使用 `isAuthenticated()` 而非具体权限（降低上报门槛）

## Phase-Local Manifest

```
ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/TraceIdFilter.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/aop/SlowApiAspect.java
ljwx-platform-app/src/main/resources/logback-spring.xml
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/FrontendErrorController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/FrontendErrorDTO.java
ljwx-platform-app/src/main/resources/db/migration/V029__create_sys_frontend_error.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysFrontendError.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysFrontendErrorMapper.java
ljwx-platform-app/src/main/resources/mapper/SysFrontendErrorMapper.xml
ljwx-platform-admin/src/composables/useErrorMonitor.ts
```

## 验收条件

1. 每个 API 响应头包含 `X-Trace-Id`
2. 日志输出包含 traceId 字段
3. SlowApiAspect 对执行超 3s 的方法输出 WARN 日志
4. V029 含 7 列审计字段，无 IF NOT EXISTS
5. FrontendErrorController POST 接口返回 200
6. useErrorMonitor.ts 无 `any` 类型，type-check 通过
