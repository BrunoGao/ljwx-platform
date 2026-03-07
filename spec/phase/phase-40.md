---
phase: 40
title: "岗位管理 (Position Management)"
targets:
  backend: true
  frontend: true
depends_on: [39]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V040__create_sys_post.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V041__create_sys_user_post.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/Post.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/UserPost.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/PostMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/UserPostMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/PostAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/PostController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/PostCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/PostUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/PostQueryDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/PostVO.java"
  - "ljwx-platform-admin/src/api/post.ts"
  - "ljwx-platform-admin/src/stores/post.ts"
  - "ljwx-platform-admin/src/views/system/post/index.vue"
---
# Phase 40 — 岗位管理

| 项目 | 值 |
|-----|---|
| Phase | 40 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L2-D05-F01 |
| 前置依赖 | Phase 39 (数据脱敏) |
| 测试契约 | `spec/tests/phase-40-post.tests.yml` |
| 优先级 | 🟡 **P1 - 组织架构完整性** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §岗位表、§用户岗位关联表
- `spec/03-api.md` — §岗位 API
- `spec/01-constraints.md` — §审计字段、§TypeScript 约束
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前系统缺少岗位管理功能,无法按岗位管理用户,组织架构管理不完整。

**解决方案**: 实现岗位管理功能,支持:
1. 岗位 CRUD
2. 用户-岗位关联（多对多）
3. 岗位排序
4. 岗位状态管理

---

## 数据库契约

### 表结构：sys_post

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| post_code | VARCHAR(50) | NOT NULL, INDEX | 岗位编码 |
| post_name | VARCHAR(100) | NOT NULL | 岗位名称 |
| post_sort | INT | NOT NULL, DEFAULT 0 | 显示顺序 |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'ENABLED' | ENABLED / DISABLED |
| remark | VARCHAR(500) | | 备注 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_tenant_post_code` (tenant_id, post_code, deleted) UNIQUE
- `idx_tenant_id` (tenant_id)

### 表结构：sys_user_post

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| user_id | BIGINT | NOT NULL, INDEX | 用户 ID |
| post_id | BIGINT | NOT NULL, INDEX | 岗位 ID |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_user_post` (tenant_id, user_id, post_id, deleted) UNIQUE
- `idx_user_id` (user_id)
- `idx_post_id` (post_id)
- `idx_tenant_id` (tenant_id)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V040__create_sys_post.sql` | 建表 + 索引 |
| `V041__create_sys_user_post.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/posts | system:post:list | — (Query Parameters) | Result<List<PostVO>> | 查询列表 |
| GET | /api/v1/posts/{id} | system:post:query | — | Result<PostVO> | 查询详情 |
| POST | /api/v1/posts | system:post:add | PostCreateDTO | Result<Long> | 创建 |
| PUT | /api/v1/posts/{id} | system:post:edit | PostUpdateDTO | Result<Void> | 更新 |
| DELETE | /api/v1/posts/{id} | system:post:delete | — | Result<Void> | 删除（软删） |

---

## DTO / VO 契约

### PostCreateDTO（创建请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| postCode | String | @NotBlank, @Size(max=50) | 岗位编码 |
| postName | String | @NotBlank, @Size(max=100) | 岗位名称 |
| postSort | Integer | @NotNull, @Min(0) | 显示顺序 |
| status | String | @NotBlank | ENABLED / DISABLED |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### PostUpdateDTO（更新请求）

与 CreateDTO 相同字段,全部可选（Partial Update）。**禁止字段**同上。

### PostQueryDTO（查询条件）

| 字段 | 类型 | 说明 |
|------|------|------|
| postCode | String | 岗位编码（模糊） |
| postName | String | 岗位名称（模糊） |
| status | String | 状态 |

**禁止字段**：`tenantId`（框架自动注入）

### PostVO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| postCode | String | 岗位编码 |
| postName | String | 岗位名称 |
| postSort | Integer | 显示顺序 |
| status | String | 状态 |
| remark | String | 备注 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`version`

---

## 业务规则

> 格式：BL-40-{序号}：[条件] → [动作] → [结果/异常]

- **BL-40-01**：创建岗位 → 检查 postCode 唯一性 → 重复则抛出 `BusinessException(POST_CODE_EXISTS)`
- **BL-40-02**：删除岗位 → 检查是否有关联用户 → 有则抛出 `BusinessException(POST_HAS_USERS)`
- **BL-40-03**：禁用岗位 → 不影响已关联用户 → 仅影响新关联
- **BL-40-04**：用户关联岗位 → 检查岗位状态 → 禁用岗位不可关联
- **BL-40-05**：TenantLineInterceptor 自动注入 tenant_id,无需代码显式传递

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-40-post.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-40-01 | 无 Token → 401 | P0 |
| TC-40-02 | 无权限 → 403 | P0 |
| TC-40-03 | 正常 CRUD | P0 |
| TC-40-04 | 租户隔离 | P0 |
| TC-40-05 | 软删除 | P0 |
| TC-40-06 | postCode 唯一性 | P0 |
| TC-40-07 | 删除岗位有关联用户 | P0 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：DTO 不含 `tenantId` 及其他禁止字段
- **AC-04**：租户隔离生效（tenant_id 由 Interceptor 注入）
- **AC-05**：软删除生效（`deleted=TRUE` 后 API 查询不返回）
- **AC-06**：postCode 唯一性校验生效
- **AC-07**：删除岗位有关联用户时拒绝
- **AC-08**：编译通过,前端 `type-check` 通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:post:list')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · `tenantId` in DTO · `any` in TypeScript
- 前端版本号：仅 `~`（tilde），禁止 `^`（caret）
- postCode 唯一性：租户内唯一

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-40-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-40-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-40-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-40-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-40-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-40-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-40-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-40-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-40-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-40-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
