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
# Phase 4: Web Module

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-architecture.md` — §模块依赖图、§POM 依赖声明（web 部分）
- `spec/03-api.md` — §统一响应、§错误码
- `spec/08-output-rules.md`

## 任务

实现 ljwx-platform-web 模块：GlobalExceptionHandler、ResponseAdvice、WebMvcConfig。

## Phase-Local Manifest

```
ljwx-platform-web/pom.xml
ljwx-platform-web/src/main/java/com/ljwx/platform/web/advice/GlobalExceptionHandler.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/advice/ResponseAdvice.java
ljwx-platform-web/src/main/java/com/ljwx/platform/web/config/WebMvcConfig.java
```

## 验收条件

1. `pom.xml` 依赖含 `ljwx-platform-security`（core 经传递获得）
2. GlobalExceptionHandler 处理常见异常并返回 Result 格式
3. ErrorCode 中定义的所有错误码均有对应异常处理
4. `./mvnw compile -pl ljwx-platform-web` 通过

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
