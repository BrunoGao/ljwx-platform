---
phase: 10
title: "Index and Contract"
targets:
  backend: true
  frontend: false
depends_on: [9]
bundle_with: [9]
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V021__create_indexes.sql"
  - "scripts/tools/export-openapi.sh"
  - "docs/contracts/.gitkeep"
---
# Phase 10: Index & Contract

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — V021
- `spec/05-backend-config.md` — §springdoc 部分
- `spec/08-output-rules.md`

## 任务

V021（常用索引）、OpenAPI export 脚本、springdoc 配置验证。

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V021__create_indexes.sql
scripts/tools/export-openapi.sh
docs/contracts/.gitkeep
```

## 验收条件

1. V021 为常用字段创建索引（tenant_id、username、created_time 等）
2. export-openapi.sh 可启动应用并导出 openapi.json
3. springdoc 在 application.yml 中配置正确
4. 编译通过

## 可 Bundle

可与 Phase 9 一起执行。

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-10-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-10-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-10-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-10-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-10-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-10-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-10-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-10-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-10-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-10-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
