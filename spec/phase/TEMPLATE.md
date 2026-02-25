---
title: "Phase Template Title"
phase: 0
targets:
  - backend
  - frontend
scope:
  - "ljwx-platform-*/src/main/java/com/ljwx/platform/*/entity/*.java"
  - "ljwx-platform-*/src/main/java/com/ljwx/platform/*/mapper/*.java"
  - "ljwx-platform-*/src/main/java/com/ljwx/platform/*/service/*.java"
  - "ljwx-platform-*/src/main/java/com/ljwx/platform/*/controller/*.java"
  - "ljwx-platform-app/src/main/resources/db/migration/V0_1__example.sql"
  - "ljwx-platform-admin/src/api/module.ts"
  - "ljwx-platform-admin/src/router/modules/module.ts"
  - "ljwx-platform-admin/src/stores/module.ts"
  - "ljwx-platform-admin/src/views/module/index.vue"
depends_on: []
gate_rules:
  - no-preauthorize
  - no-caret
  - dto-no-tenant-id
  - no-any
  - no-if-not-exists
  - wrong-env-var
  - dag-violation
  - audit-columns
---

# Phase N: 标题

## 目标

本 Phase 要实现的功能概述。

## 读取清单

> 严格按此清单读取，禁止扫描整个 spec/ 目录

- `spec/01-constraints.md` §C01（多租户），§C02（权限）
- `spec/04-database.md` §相关表结构章节
- `spec/03-api.md` §相关接口章节

## 后端任务

### 实体层

**表名**：`t_xxx`
**基类**：继承 `BaseEntity`（已含 7 列审计字段）

| 字段名 | 类型 | 约束 | 说明 |
|-------|------|------|------|
| id | BIGINT | PK | 主键 |
| name | VARCHAR(100) | NOT NULL | 名称 |

### Mapper

方法列表：
- `selectByXxx(XxxQueryDTO)` — 条件查询（TenantLineInterceptor 自动注入 tenant_id）

### Service

- `listXxx(XxxQueryDTO): PageResult<XxxVO>` — 列表查询
- `createXxx(XxxCreateDTO): Long` — 创建，返回 ID

### Controller

REST 路径：`/api/v1/xxx`

| 方法 | 路径 | 权限 | 说明 |
|-----|------|------|------|
| GET | /api/v1/xxx | `xxx:read` | 分页列表 |
| POST | /api/v1/xxx | `xxx:write` | 创建 |
| PUT | /api/v1/xxx/{id} | `xxx:write` | 更新 |
| DELETE | /api/v1/xxx/{id} | `xxx:delete` | 删除 |

### Flyway 迁移

文件：`V{N}_1__create_xxx_table.sql`

## 前端任务

### API 层

文件：`src/api/xxx.ts`
- `getXxxList(params?: XxxQueryDTO): Promise<Result<PageResult<XxxVO>>>`
- `createXxx(data: XxxCreateDTO): Promise<Result<number>>`

### 路由

文件：`src/router/modules/xxx.ts`
- `/xxx` — 列表页

### 视图

文件：`src/views/xxx/index.vue`
- 搜索表单 + `el-table` 列表 + 分页

## 验收条件

1. `mvn clean compile -f pom.xml -q` 通过
2. `pnpm run type-check` 通过（在 ljwx-platform-admin/）
3. `bash scripts/gates/gate-all.sh N` 全部 PASS
4. 无 TypeScript `any`
5. 所有 Controller 方法有 `@PreAuthorize`
6. 迁移 SQL 含 7 列审计字段且无 `IF NOT EXISTS`

## Test Cases

每个 Phase 必须定义可执行测试用例，并使用唯一 ID（示例：`TC-20-01`）。

| TC ID | Endpoint | 权限 | 预期状态 | 关键断言 |
|------|----------|------|---------|---------|
| TC-NN-01 | GET /api/v1/xxx | `xxx:read` | 401 | 无 token 拒绝访问 |
| TC-NN-02 | GET /api/v1/xxx | `xxx:read` | 403 | 无权限 token 被拒绝 |
| TC-NN-03 | GET /api/v1/xxx | `xxx:read` | 200 | 仅返回当前租户数据 |
| TC-NN-04 | POST /api/v1/xxx | `xxx:write` | 200 | 创建成功并返回 ID |
| TC-NN-05 | PUT /api/v1/xxx/{id} | `xxx:write` | 200 | 更新成功，数据可见 |
| TC-NN-06 | DELETE /api/v1/xxx/{id} | `xxx:delete` | 200 | 软删除后列表不可见 |
| TC-NN-07 | POST /api/v1/xxx | `xxx:write` | 400 | 参数校验失败 |

## PHASE_MANIFEST.txt 记录格式

```
## PHASE N
Status: PASSED

ljwx-platform-*/src/.../XxxEntity.java
ljwx-platform-*/src/.../XxxMapper.java
ljwx-platform-*/src/.../XxxService.java
ljwx-platform-*/src/.../XxxController.java
ljwx-platform-app/src/main/resources/db/migration/VN_1__create_xxx_table.sql
ljwx-platform-admin/src/api/xxx.ts
ljwx-platform-admin/src/router/modules/xxx.ts
ljwx-platform-admin/src/views/xxx/index.vue
```
