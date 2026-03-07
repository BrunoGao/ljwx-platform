---
phase: 4
title: "Web Module"
targets:
  backend: true
  frontend: false
depends_on: [2, 3]
bundle_with: [5]
scope:
  - "ljwx-platform-web/**"
---
# Phase 4 — Web 层模块 (Web Module)

| 项目 | 值 |
|-----|---|
| Phase | 4 |
| 模块 | ljwx-platform-web |
| Feature | F-004 (全局异常处理) |
| 前置依赖 | Phase 2 (Data), Phase 3 (Security) |
| 测试契约 | `spec/tests/phase-04-web.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §模块依赖图
- `spec/03-api.md` — §统一响应、§错误码
- `spec/08-output-rules.md`

---

## 类契约

### GlobalExceptionHandler（全局异常处理器）

| 异常类型 | HTTP状态 | ErrorCode | 说明 |
|----------|----------|-----------|------|
| AuthenticationException | 401 | UNAUTHORIZED | 未认证 |
| AccessDeniedException | 403 | FORBIDDEN | 无权限 |
| MethodArgumentNotValidException | 400 | VALIDATION_ERROR | 参数校验失败 |
| BusinessException | 400 | BUSINESS_ERROR | 业务异常 |
| Exception | 500 | INTERNAL_ERROR | 系统异常 |

返回格式：`Result<Void>`

### ResponseAdvice（响应增强）

自动包装 Controller 返回值为 `Result<T>` 格式（如果未包装）。

### WebMvcConfig（Web 配置）

- CORS 配置
- 日期格式化
- 静态资源映射

---

## 业务规则

- **BL-04-01**：web 模块依赖 security 和 data（通过 security 传递获得 core）
- **BL-04-02**：所有异常统一返回 Result 格式，包含 traceId
- **BL-04-03**：参数校验异常返回具体字段错误信息
- **BL-04-04**：系统异常不暴露堆栈信息给前端

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-04-web.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-04-01 | pom.xml 依赖 security | P0 |
| TC-04-02 | GlobalExceptionHandler 处理 AuthenticationException → 401 | P0 |
| TC-04-03 | GlobalExceptionHandler 处理 AccessDeniedException → 403 | P0 |
| TC-04-04 | GlobalExceptionHandler 处理 MethodArgumentNotValidException → 400 | P0 |
| TC-04-05 | 所有异常返回 Result 格式 | P0 |
| TC-04-06 | 编译通过 | P0 |

---

## 验收条件

- **AC-01**：`pom.xml` 依赖含 `ljwx-platform-security`
- **AC-02**：GlobalExceptionHandler 处理常见异常并返回 Result 格式
- **AC-03**：ErrorCode 中定义的所有错误码均有对应异常处理
- **AC-04**：`./mvnw compile -pl ljwx-platform-web` 通过

---

## 关键约束

- 禁止：异常堆栈信息暴露给前端 · 未包装的响应格式
- 所有异常必须返回 Result<Void> 格式
- traceId 必须包含在响应中

## 可 Bundle

可与 Phase 5 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-04-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-04-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-04-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-04-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-04-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-04-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-04-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-04-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-04-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-04-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
