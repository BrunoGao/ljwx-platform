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
