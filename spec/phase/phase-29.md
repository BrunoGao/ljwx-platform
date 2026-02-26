---
phase: 29
title: "Observability TraceId Structured Logging Slow API"
targets:
  backend: true
  frontend: true
depends_on: [28]
bundle_with: [30]
scope:
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/filter/TraceIdFilter.java"
  - "ljwx-platform-web/src/main/java/com/ljwx/platform/web/aop/SlowApiAspect.java"
  - "ljwx-platform-app/src/main/resources/logback-spring.xml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/FrontendErrorController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/FrontendErrorDTO.java"
  - "ljwx-platform-app/src/main/resources/db/migration/V031__create_sys_frontend_error.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysFrontendError.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysFrontendErrorMapper.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysFrontendErrorMapper.xml"
  - "ljwx-platform-admin/src/composables/useErrorMonitor.ts"
---
# Phase 29: Observability — TraceId / Structured Logging / Slow API

## Overview

| 项目 | 内容 |
|------|------|
| Phase | 29 |
| 模块 | ljwx-platform-web / ljwx-platform-app / ljwx-platform-admin |
| Feature | 请求链路追踪、结构化日志、慢接口监控、前端错误上报 |
| 前置依赖 | Phase 28 |
| 测试契约 | spec/tests/phase-29-observability.tests.yml |

## 读取清单
- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §DAG 依赖
- `spec/04-database.md` — 审计字段规范
- `spec/08-output-rules.md`

## DB 契约

### sys_frontend_error（V031）

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键 |
| error_message | VARCHAR(1000) | NOT NULL | 错误信息 |
| stack_trace | TEXT | NOT NULL DEFAULT '' | 堆栈信息 |
| page_url | VARCHAR(500) | NOT NULL DEFAULT '' | 发生页面 |
| user_agent | VARCHAR(500) | NOT NULL DEFAULT '' | 浏览器信息 |
| tenant_id | BIGINT | NOT NULL DEFAULT 0 | 租户 ID（审计字段） |
| created_by | BIGINT | NOT NULL DEFAULT 0 | 创建人（审计字段） |
| created_time | TIMESTAMP | NOT NULL DEFAULT NOW() | 创建时间（审计字段） |
| updated_by | BIGINT | NOT NULL DEFAULT 0 | 更新人（审计字段） |
| updated_time | TIMESTAMP | NOT NULL DEFAULT NOW() | 更新时间（审计字段） |
| deleted | BOOLEAN | NOT NULL DEFAULT FALSE | 逻辑删除（审计字段） |
| version | INT | NOT NULL DEFAULT 1 | 乐观锁（审计字段） |

### Flyway 文件

| 文件 | 说明 |
|------|------|
| V031__create_sys_frontend_error.sql | 创建 sys_frontend_error 表，禁止 IF NOT EXISTS |

## API 契约

| 方法 | 路径 | 权限 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | /api/v1/frontend-errors | isAuthenticated() | FrontendErrorDTO | Result\<Void\> |

### FrontendErrorDTO 字段

| 字段 | 类型 | 约束 |
|------|------|------|
| errorMessage | String | @NotBlank |
| stackTrace | String | @NotBlank |
| pageUrl | String | @NotBlank |
| userAgent | String | @NotBlank |

## 组件契约

| 组件 | 位置 | 核心行为 |
|------|------|----------|
| TraceIdFilter | web 模块，order=0 | 读 X-Trace-Id header 或生成 UUID 前 16 位，写入 MDC，响应头回传，finally 清理 MDC |
| SlowApiAspect | web 模块 | 切所有 @RestController 方法，执行时间 >= 3000ms 输出 WARN，>= 10000ms 输出 ERROR，含 traceId |
| logback-spring.xml | app 模块 resources | JSON 格式，含 time/level/traceId/tenantId/userId/logger/msg 字段，开发环境可读格式 |
| useErrorMonitor.ts | admin composables | 监听 window.onerror + unhandledrejection，防抖 5s，POST /api/v1/frontend-errors，main.ts 初始化调用 |

## 业务规则

- **BL-29-01**：请求头存在 `X-Trace-Id` → 直接使用该值；不存在 → 生成 UUID 取前 16 位作为 traceId
- **BL-29-02**：TraceIdFilter 将 traceId/tenantId/userId 写入 MDC，响应头写入 `X-Trace-Id: {traceId}`，finally 块强制执行 `MDC.clear()`
- **BL-29-03**：SlowApiAspect 统计方法执行时间，>= 3000ms → 输出 WARN 日志（含路径、方法名、耗时、traceId）；>= 10000ms → 输出 ERROR 日志
- **BL-29-04**：useErrorMonitor 以错误 message 为 key，同一错误 5 秒内只上报一次，超出防抖窗口后可再次上报

## P0 测试摘要

| ID | 优先级 | 场景 |
|----|--------|------|
| TC-29-01 | P0 | POST /api/v1/frontend-errors 无 Token → 401 |
| TC-29-02 | P0 | POST /api/v1/frontend-errors 已登录有效 body → 200 |
| TC-29-03 | P0 | POST /api/v1/frontend-errors body 缺必填字段 → 400 |
| TC-29-04 | P0 | 任意 API 响应头包含 X-Trace-Id |
| TC-29-05 | P0 | V031 含 7 列审计字段，无 IF NOT EXISTS |
| TC-29-06 | P0 | useErrorMonitor.ts 无 TypeScript any，type-check 通过 |
| TC-29-07 | P1 | 模拟执行时间 > 3000ms 的接口，应用日志出现 WARN SlowApi |

完整用例见 [spec/tests/phase-29-observability.tests.yml](../tests/phase-29-observability.tests.yml)

## 关键约束

- TraceIdFilter 在 web 模块，禁止 import security/data 包（DAG 合规）
- SlowApiAspect 在 web 模块，需要 spring-boot-starter-aop 依赖
- V031 含 7 列审计字段，无 IF NOT EXISTS
- FrontendErrorController 权限注解为 `@PreAuthorize("isAuthenticated()")`，不使用 hasAuthority
- useErrorMonitor.ts 禁止 any 类型，必须在 main.ts 中调用初始化
- 与 Phase 30 按 bundle 落地（`V030` 与 `V031` 同批提交），避免迁移版本顺序风险

## 验收条件

1. 每个 API 响应头包含 X-Trace-Id
2. 日志输出包含 traceId 字段（JSON 结构化格式）
3. SlowApiAspect 对执行超 3s 的方法输出 WARN 日志
4. V031 含 7 列审计字段，无 IF NOT EXISTS
5. POST /api/v1/frontend-errors 已登录时返回 200
6. useErrorMonitor.ts 无 any 类型，type-check 通过
