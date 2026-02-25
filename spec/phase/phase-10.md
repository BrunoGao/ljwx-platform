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
# Phase 10 — 索引与契约 (Index and Contract)

| 项目 | 值 |
|-----|---|
| Phase | 10 |
| 模块 | ljwx-platform-app |
| Feature | F-010 (数据库索引与 API 契约) |
| 前置依赖 | Phase 9 (Logs Notice and File) |
| 测试契约 | `spec/tests/phase-10-index.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — V021
- `spec/05-backend-config.md` — §springdoc 部分
- `spec/08-output-rules.md`

---

## 数据库契约

### V021__create_indexes.sql（索引）

| 表名 | 索引名 | 列 | 类型 | 说明 |
|------|--------|---|------|------|
| sys_user | idx_user_tenant_username | tenant_id, username | BTREE | 租户+用户名查询 |
| sys_user | idx_user_tenant_phone | tenant_id, phone | BTREE | 租户+手机号查询 |
| sys_user | idx_user_created_time | created_time | BTREE | 创建时间排序 |
| sys_role | idx_role_tenant | tenant_id | BTREE | 租户查询 |
| sys_permission | idx_permission_tenant | tenant_id | BTREE | 租户查询 |
| sys_menu | idx_menu_tenant_parent | tenant_id, parent_id | BTREE | 租户+父菜单查询 |
| sys_dict_data | idx_dict_type | dict_type | BTREE | 字典类型查询 |
| sys_operation_log | idx_log_tenant_time | tenant_id, created_time | BTREE | 租户+时间查询 |
| sys_login_log | idx_login_tenant_time | tenant_id, login_time | BTREE | 租户+登录时间查询 |
| sys_file | idx_file_tenant | tenant_id | BTREE | 租户查询 |

**关键约束**：
- 所有多租户表必须有 tenant_id 索引
- 常用查询字段必须有索引
- 时间字段用于排序的必须有索引

---

## OpenAPI 契约

### export-openapi.sh（导出脚本）

功能：
1. 启动 Spring Boot 应用
2. 等待应用就绪（健康检查）
3. 调用 `/v3/api-docs` 导出 OpenAPI JSON
4. 保存到 `docs/contracts/openapi.json`
5. 关闭应用

### springdoc 配置（application.yml）

```yaml
springdoc:
  api-docs:
    enabled: true
    path: /v3/api-docs
  swagger-ui:
    enabled: true
    path: /swagger-ui.html
  group-configs:
    - group: 'system'
      paths-to-match: '/api/**'
```

---

## 业务规则

- **BL-10-01**：所有包含 tenant_id 的表必须有 tenant_id 索引
- **BL-10-02**：常用查询字段（username, phone, dict_type）必须有索引
- **BL-10-03**：时间字段用于排序的（created_time, login_time）必须有索引
- **BL-10-04**：复合索引遵循最左前缀原则（tenant_id 在前）
- **BL-10-05**：export-openapi.sh 必须等待应用就绪后再导出
- **BL-10-06**：OpenAPI JSON 必须包含所有 Controller 的端点定义

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-10-index.tests.yml`**。

P0 强制覆盖：

| ID | 场景 | P |
|----|------|---|
| TC-10-01 | sys_user 表有 tenant_id 索引 | P0 |
| TC-10-02 | sys_operation_log 表有复合索引 | P0 |
| TC-10-03 | export-openapi.sh 可执行 | P0 |
| TC-10-04 | OpenAPI JSON 包含所有端点 | P0 |
| TC-10-05 | Swagger UI 可访问 | P0 |
| TC-10-06 | 索引提升查询性能 | P0 |

---

## 验收条件

- **AC-01**：V021 为常用字段创建索引（tenant_id、username、created_time 等）
- **AC-02**：所有多租户表有 tenant_id 索引
- **AC-03**：export-openapi.sh 可启动应用并导出 openapi.json
- **AC-04**：springdoc 在 application.yml 中配置正确
- **AC-05**：Swagger UI 可通过 /swagger-ui.html 访问
- **AC-06**：`./mvnw compile -pl ljwx-platform-app` 通过

---

## 关键约束

- 禁止：缺少 tenant_id 索引 · 复合索引顺序错误 · OpenAPI 导出失败
- 索引命名规范：`idx_{table}_{columns}`
- 复合索引遵循最左前缀原则

## 可 Bundle

可与 Phase 9 一起执行。
