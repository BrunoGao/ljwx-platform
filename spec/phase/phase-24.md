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
# Phase 24: Tenant Package, Notice Read & Import/Export

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §TenantPackage、§Notice（已读扩展）
- `spec/04-database.md` — sys_tenant_package、sys_notice_user 表结构
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

## 任务

### 1. 租户套餐（V027）

**表 sys_tenant_package**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| name | VARCHAR(64) NOT NULL | 套餐名称 |
| menu_ids | TEXT NOT NULL DEFAULT '' | 关联菜单 ID 列表（逗号分隔） |
| max_users | INT NOT NULL DEFAULT 100 | 最大用户数 |
| max_storage_mb | INT NOT NULL DEFAULT 1024 | 最大存储（MB） |
| status | SMALLINT NOT NULL DEFAULT 1 | 1=启用 0=停用 |
| + 7 列审计字段 | | |

sys_tenant 表增加 package_id 列（V027 中 ALTER TABLE）。

API：`/api/v1/tenant-packages`（CRUD，权限前缀 `system:tenant-package:`）

### 2. 通知已读状态（V028）

**表 sys_notice_user**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| notice_id | BIGINT NOT NULL | 公告 ID |
| user_id | BIGINT NOT NULL | 用户 ID |
| read_time | TIMESTAMPTZ | 已读时间，NULL=未读 |
| + 7 列审计字段 | | |

NoticeController 新增：
- `PUT /api/v1/notices/{id}/read` — 标记已读（权限 `system:notice:read`）
- `GET /api/v1/notices/unread-count` — 未读数（权限 `system:notice:list`）

### 3. 导入导出

UserController 新增：
- `GET /api/v1/users/export` — 导出 Excel（权限 `system:user:export`）
- `POST /api/v1/users/import` — 导入 Excel（权限 `system:user:import`，multipart/form-data）

使用 Apache POI（通过 spring-boot-starter 间接引入）或 EasyExcel（需在 pom.xml 中添加依赖，版本硬编码）。

### 前端

- `src/api/tenantPackage.ts`
- `src/views/system/tenantPackage/index.vue` — 套餐管理页面

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V027__create_sys_tenant_package.sql
ljwx-platform-app/src/main/resources/db/migration/V028__create_sys_notice_user.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysTenantPackage.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysNoticeUser.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysTenantPackageMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysNoticeUserMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/TenantPackageAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/TenantPackageController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/TenantPackageCreateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/TenantPackageUpdateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/TenantPackageVO.java
ljwx-platform-app/src/main/resources/mapper/SysTenantPackageMapper.xml
ljwx-platform-app/src/main/resources/mapper/SysNoticeUserMapper.xml
ljwx-platform-admin/src/api/tenantPackage.ts
ljwx-platform-admin/src/views/system/tenantPackage/index.vue
```

## 验收条件

1. V027/V028 含 7 列审计字段，无 IF NOT EXISTS
2. TenantPackageController 所有方法有 @PreAuthorize
3. 导出接口返回 application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
4. 编译通过，type-check 通过
