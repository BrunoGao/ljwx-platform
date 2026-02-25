---
phase: {NN}
title: "{功能名称} ({English Name})"
targets:
  backend: true   # 是否含后端文件
  frontend: true  # 是否含前端文件
depends_on: [{前置 Phase 编号}]
bundle_with: []   # 同批次执行的 Phase（同时生成）
scope:            # 本 Phase 允许写入的文件路径（pre-edit-guard.sh 白名单）
  - "ljwx-platform-app/src/main/resources/db/migration/V{NNN}__create_{table}.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/{Entity}.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/{Entity}Mapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/{Module}AppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/{Module}Controller.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/{Entity}CreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/{Entity}UpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/{Entity}QueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/{Entity}VO.java"
  - "ljwx-platform-app/src/main/resources/mapper/{Entity}Mapper.xml"
  # 前端文件（如有）
  - "ljwx-platform-admin/src/api/{module}.ts"
  - "ljwx-platform-admin/src/stores/{module}.ts"
  - "ljwx-platform-admin/src/views/{module}/index.vue"
---
# Phase {NN} — {功能名称} ({English Name})

| 项目 | 值 |
|-----|---|
| Phase | {NN} |
| 模块 | ljwx-platform-app (后端){, ljwx-platform-admin (前端)} |
| Feature | F-{NNN} (如有对应 Feature Brief) |
| 前置依赖 | Phase {X} ({依赖说明}) |
| 测试契约 | `spec/tests/phase-{NN}-{module}.tests.yml` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §{相关表名} 表结构
- `spec/03-api.md` — §{相关路由段}
- `spec/01-constraints.md` — §审计字段、§TypeScript 约束
- `spec/08-output-rules.md`

---

## 数据库契约

### 表结构：{table_name}

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| {业务字段1} | {类型} | {约束} | {说明} |
| {业务字段2} | {类型} | {约束} | {说明} |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

> 审计字段（最后 7 列）由 BaseEntity 自动管理，禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V{NNN}__create_{table}.sql` | 建表 + 索引 |
| `V{NNN}_1__seed_{table}.sql` | 初始数据（如有） |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/{resource} | {module}:{entity}:list | — | Result<List<{Entity}VO>> | 查询列表 |
| GET | /api/v1/{resource}/{id} | {module}:{entity}:detail | — | Result<{Entity}VO> | 查询详情 |
| POST | /api/v1/{resource} | {module}:{entity}:create | {Entity}CreateDTO | Result<Long> | 创建 |
| PUT | /api/v1/{resource}/{id} | {module}:{entity}:update | {Entity}UpdateDTO | Result<Void> | 更新 |
| DELETE | /api/v1/{resource}/{id} | {module}:{entity}:delete | — | Result<Void> | 删除（软删） |

---

## DTO / VO 契约

### {Entity}CreateDTO（创建请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| {field1} | {type} | @NotBlank | {说明} |
| {field2} | {type} | @NotNull | {说明} |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### {Entity}UpdateDTO（更新请求）

与 CreateDTO 相同字段，全部可选（Partial Update）。**禁止字段**同上。

### {Entity}QueryDTO（查询条件）

| 字段 | 类型 | 说明 |
|------|------|------|
| {field} | {type} | {说明} |

**禁止字段**：`tenantId`（框架自动注入）

### {Entity}VO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| {业务字段} | {type} | {说明} |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`version`

---

## 实体 / 服务契约

```
Entity  : {Entity} extends BaseEntity
          业务字段见上表，审计字段由 BaseEntity 继承，勿重复声明

Mapper  : {Entity}Mapper extends BaseMapper<{Entity}>
          如需自定义 SQL，创建 {Entity}Mapper.xml

Service : {Module}AppService（非 IService，应用服务层）
          方法: list{Entity}s(), get{Entity}(id), create{Entity}(dto),
                update{Entity}(id, dto), delete{Entity}(id)
```

---

## 业务规则

> 格式：BL-{NN}-{序号}：\[条件\] → \[动作\] → \[结果/异常\]

- **BL-{NN}-01**：{条件} → {动作} → {结果}
- **BL-{NN}-02**：{条件} → {动作} → 抛出 `BusinessException({ErrorCode.XXX})`
- **BL-{NN}-03**：删除时有关联子记录 → 拒绝删除 → 返回业务异常
- **BL-{NN}-04**：TenantLineInterceptor 自动注入 tenant_id，无需代码显式传递

> 实现取舍（如内存建树 vs 递归SQL）→ 见 `spec/adr/ADR-{NN}-{title}.md`

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-{NN}-{module}.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-{NN}-01 | 无 Token → 401 | P0 |
| TC-{NN}-02 | 无权限 → 403 | P0 |
| TC-{NN}-03 | 正常 CRUD | P0 |
| TC-{NN}-04 | 租户隔离 | P0 |
| TC-{NN}-05 | 软删除 | P0 |
| TC-{NN}-06 | 核心业务规则 | P0 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段，无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize("hasAuthority('...')")`
- **AC-03**：DTO 不含 `tenantId` 及其他禁止字段
- **AC-04**：租户隔离生效（tenant_id 由 Interceptor 注入）
- **AC-05**：软删除生效（`deleted=TRUE` 后 API 查询不返回）
- **AC-06**：编译通过，前端 `type-check` 通过，所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('{module}:{entity}:{action}')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · `tenantId` in DTO · `any` in TypeScript
- 前端版本号：仅 `~`（tilde），禁止 `^`（caret）
