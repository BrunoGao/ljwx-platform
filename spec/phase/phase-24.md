---
phase: 24
title: "Tenant Package Notice Read and Import Export"
targets:
  backend: true
  frontend: true
depends_on: [23]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V027__create_sys_tenant_package.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V028__create_sys_notice_user.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysTenantPackage.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysNoticeUser.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysTenantPackageMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysNoticeUserMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/TenantPackageAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/TenantPackageController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/TenantPackageCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/TenantPackageUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/TenantPackageVO.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysTenantPackageMapper.xml"
  - "ljwx-platform-app/src/main/resources/mapper/SysNoticeUserMapper.xml"
  - "ljwx-platform-admin/src/api/tenantPackage.ts"
  - "ljwx-platform-admin/src/views/system/tenantPackage/index.vue"
---
# Phase 24 — Tenant Package, Notice Read & Import/Export

| 项目 | 值 |
|-----|---|
| Phase | 24 |
| 模块 | ljwx-platform-app（后端）+ ljwx-platform-admin（前端） |
| Feature | 租户套餐管理 / 通知已读状态 / 用户导入导出 |
| 前置依赖 | Phase 23 (Admin Frontend Pages Batch 2) |
| 测试契约 | `spec/tests/phase-24-tenantpackage.tests.yml` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §TenantPackage、§Notice（已读扩展）
- `spec/04-database.md` — sys_tenant_package、sys_notice_user 表结构
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

---

## 数据库契约

### 表结构：sys_tenant_package

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| name | VARCHAR(64) | NOT NULL | 套餐名称 |
| menu_ids | TEXT | NOT NULL, DEFAULT '' | 关联菜单 ID 列表（逗号分隔） |
| max_users | INT | NOT NULL, DEFAULT 100 | 最大用户数 |
| max_storage_mb | INT | NOT NULL, DEFAULT 1024 | 最大存储（MB） |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 1=启用 0=停用 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

> 同一 V027 迁移文件中额外执行 `ALTER TABLE sys_tenant ADD COLUMN package_id BIGINT NOT NULL DEFAULT 0;`（见 BL-24-01）。

### 表结构：sys_notice_user

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| notice_id | BIGINT | NOT NULL | 公告 ID（外键 sys_notice.id） |
| user_id | BIGINT | NOT NULL | 用户 ID（外键 sys_user.id） |
| read_time | TIMESTAMPTZ | NULL | 已读时间，NULL=未读 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

> 7 列审计字段（tenant_id, created_by, created_time, updated_by, updated_time, deleted, version）均 NOT NULL + DEFAULT（read_time 除外，允许 NULL 表示未读状态）。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V027__create_sys_tenant_package.sql` | 建表 sys_tenant_package + ALTER TABLE sys_tenant ADD COLUMN package_id |
| `V028__create_sys_notice_user.sql` | 建表 sys_notice_user + 唯一索引 idx_notice_user(notice_id, user_id, tenant_id) |

禁止：`IF NOT EXISTS`、建表文件中混 DML。

---

## API 契约

### 租户套餐

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/tenant-packages | system:tenant-package:list | — | Result<PageResult\<TenantPackageVO\>> | 分页列表 |
| GET | /api/v1/tenant-packages/{id} | system:tenant-package:detail | — | Result\<TenantPackageVO\> | 详情 |
| POST | /api/v1/tenant-packages | system:tenant-package:create | TenantPackageCreateDTO | Result\<Long\> | 创建 |
| PUT | /api/v1/tenant-packages/{id} | system:tenant-package:update | TenantPackageUpdateDTO | Result\<Void\> | 更新 |
| DELETE | /api/v1/tenant-packages/{id} | system:tenant-package:delete | — | Result\<Void\> | 软删除 |

### 通知已读（NoticeController 扩展）

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| PUT | /api/v1/notices/{id}/read | system:notice:read | — | Result\<Void\> | 标记已读（幂等） |
| GET | /api/v1/notices/unread-count | system:notice:list | — | Result\<Long\> | 未读数量 |

### 用户导入导出（UserController 扩展）

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/users/export | system:user:export | — | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet | 导出 Excel |
| POST | /api/v1/users/import | system:user:import | multipart/form-data（file） | Result\<ImportResultVO\> | 导入 Excel |

---

## DTO / VO 契约

### TenantPackageCreateDTO

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| name | String | @NotBlank, @Size(max=64) | 套餐名称 |
| menuIds | String | — | 菜单 ID 列表（逗号分隔） |
| maxUsers | Integer | @Min(1) | 最大用户数（默认 100） |
| maxStorageMb | Integer | @Min(1) | 最大存储 MB（默认 1024） |
| status | Integer | — | 1=启用 0=停用（默认 1） |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### TenantPackageUpdateDTO

与 TenantPackageCreateDTO 相同字段，全部可选（Partial Update）。**禁止字段**同上。

### TenantPackageVO

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| name | String | 套餐名称 |
| menuIds | String | 关联菜单 ID |
| maxUsers | Integer | 最大用户数 |
| maxStorageMb | Integer | 最大存储 MB |
| status | Integer | 状态 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`version`

---

## 实体 / 服务契约

```
Entity  : SysTenantPackage extends BaseEntity
          SysNoticeUser extends BaseEntity

Mapper  : SysTenantPackageMapper extends BaseMapper<SysTenantPackage>
          SysNoticeUserMapper extends BaseMapper<SysNoticeUser>
          自定义 SQL 分别在对应 .xml 中

Service : TenantPackageAppService — listPackages(query), getPackage(id),
                                    createPackage(dto), updatePackage(id, dto), deletePackage(id)

Controller 扩展（scope 外文件的最小化 PATCH）：
  NoticeController  — markAsRead(id), getUnreadCount()
  UserController    — exportUsers(response), importUsers(file)
```

> EasyExcel 依赖需在 `ljwx-platform-app/pom.xml` 中硬编码版本号（禁止 `${latest.version}`）。

---

## 业务规则

- **BL-24-01**：`sys_tenant.package_id` 列在 V027 的同一 migration 文件中通过 `ALTER TABLE sys_tenant ADD COLUMN package_id BIGINT NOT NULL DEFAULT 0;` 添加，禁止新建单独迁移文件
- **BL-24-02**：`PUT /api/v1/notices/{id}/read` 幂等 — 若 sys_notice_user 记录已存在且 read_time 非 NULL，则不执行更新（直接返回 200），避免覆盖首次已读时间
- **BL-24-03**：`GET /api/v1/users/export` 响应 Content-Type 必须为 `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`，Content-Disposition 包含 `attachment; filename="users.xlsx"`
- **BL-24-04**：`POST /api/v1/users/import` 需校验文件扩展名为 `.xlsx`，行数超过 1000 行 → 拒绝并返回业务异常；每行缺失必填字段（username）→ 记录到 ImportResultVO.errors 列表，其余行继续导入

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-24-tenantpackage.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-24-01 | 无 Token → 401（套餐/导出接口） | P0 |
| TC-24-02 | 无权限 → 403（各权限注解验证） | P0 |
| TC-24-03 | 正常 CRUD 套餐（create/list/detail/update/delete） | P0 |
| TC-24-04 | 标记通知已读（幂等验证） | P0 |
| TC-24-05 | 获取未读数量 | P0 |
| TC-24-06 | 导出 Excel（Content-Type 验证） | P0 |
| TC-24-07 | 导入 Excel 成功 | P0 |
| TC-24-08 | 导入 Excel 超 1000 行 → 业务异常 | P0 |

---

## 验收条件

- **AC-01**：V027/V028 含 7 列审计字段，无 `IF NOT EXISTS`
- **AC-02**：TenantPackageController 所有方法有 `@PreAuthorize("hasAuthority('system:tenant-package:...')")`
- **AC-03**：`PUT /api/v1/notices/{id}/read` 幂等，多次调用结果相同
- **AC-04**：导出接口响应 Content-Type 为 `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- **AC-05**：导入接口校验行数上限（>1000 → 拒绝），缺失必填字段记录到错误列表
- **AC-06**：DTO 不含 `tenantId`；EasyExcel 版本在 pom.xml 中硬编码
- **AC-07**：编译通过，前端 `type-check` 通过，所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:tenant-package:{action}')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · `tenantId` in DTO · `any` in TypeScript
- Flyway：V027 中包含建表 + ALTER TABLE（单文件），禁止分开两个文件
- pom.xml 版本：EasyExcel 版本必须硬编码数字，禁止 `${latest.version}`
- 前端版本号：仅 `~`（tilde），禁止 `^`（caret）
