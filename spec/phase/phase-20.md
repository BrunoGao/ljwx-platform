---
phase: 20
title: "Menu Management and Dynamic Routes"
targets:
  backend: true
  frontend: true
depends_on: [19]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V022__create_sys_menu.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V023__seed_sys_menu.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysMenu.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysMenuMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/MenuAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/MenuController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/MenuCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/MenuUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/MenuVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/MenuTreeVO.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysMenuMapper.xml"
  - "ljwx-platform-admin/src/api/menu.ts"
  - "ljwx-platform-admin/src/stores/menu.ts"
  - "ljwx-platform-admin/src/views/system/menu/index.vue"
---
# Phase 20: Menu Management & Dynamic Routes

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Menus 路由
- `spec/04-database.md` — sys_menu 表结构
- `spec/01-constraints.md` — §TypeScript 约束、§审计字段
- `spec/08-output-rules.md`

## 任务

### 后端

**表 sys_menu**（V022）：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| parent_id | BIGINT NOT NULL DEFAULT 0 | 父节点，0 = 根 |
| name | VARCHAR(64) NOT NULL | 菜单名称 |
| path | VARCHAR(200) NOT NULL DEFAULT '' | 路由路径 |
| component | VARCHAR(200) NOT NULL DEFAULT '' | 组件路径 |
| icon | VARCHAR(100) NOT NULL DEFAULT '' | 图标 |
| sort | INT NOT NULL DEFAULT 0 | 排序 |
| menu_type | SMALLINT NOT NULL DEFAULT 0 | 0=目录 1=菜单 2=按钮 |
| permission | VARCHAR(100) NOT NULL DEFAULT '' | 权限字符串 |
| visible | SMALLINT NOT NULL DEFAULT 1 | 1=显示 0=隐藏 |
| + 7 列审计字段 | | |

V023 种子数据：插入系统管理目录及用户/角色/菜单/部门/字典/配置/日志/文件/公告子菜单，permission 对应已有 RBAC 字符串。

API：`/api/v1/menus`

| 方法 | 路径 | 权限 |
|------|------|------|
| GET | /api/v1/menus | `system:menu:list` |
| GET | /api/v1/menus/tree | `system:menu:list`（返回树形结构） |
| GET | /api/v1/menus/{id} | `system:menu:detail` |
| POST | /api/v1/menus | `system:menu:create` |
| PUT | /api/v1/menus/{id} | `system:menu:update` |
| DELETE | /api/v1/menus/{id} | `system:menu:delete` |

新增权限种子（V023 中追加）：`system:menu:list`, `system:menu:detail`, `system:menu:create`, `system:menu:update`, `system:menu:delete`

### 前端

- `src/api/menu.ts` — 调用上述 6 个接口
- `src/stores/menu.ts` — 存储菜单树，提供 `fetchMenuTree()` action
- `src/views/system/menu/index.vue` — 树形表格（el-table 树形模式），支持新增/编辑/删除

## 关键约束

- sys_menu 含 7 列审计字段，无 IF NOT EXISTS
- MenuController 每个方法有 @PreAuthorize
- 前端无 any，strict: true

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-20-01 | GET /api/v1/menus | `system:menu:list` | 401 | 无 token 返回 Unauthorized |
| TC-20-02 | GET /api/v1/menus | `system:menu:list` | 403 | 无权限 token 返回 Forbidden |
| TC-20-03 | GET /api/v1/menus | `system:menu:list` | 200 | 返回数组结构 |
| TC-20-04 | GET /api/v1/menus/tree | `system:menu:list` | 200 | 返回树形数组 |
| TC-20-05 | GET /api/v1/menus/{id} | `system:menu:detail` | 404/4xx | 不存在 ID 返回业务错误 |
| TC-20-06 | POST /api/v1/menus | `system:menu:create` | 400 | 缺少 `parentId` 校验失败 |
| TC-20-07 | POST /api/v1/menus | `system:menu:create` | 400 | 缺少 `name` 校验失败 |
| TC-20-08 | POST /api/v1/menus | `system:menu:create` | 400 | 缺少 `menuType` 校验失败 |
| TC-20-09 | POST /api/v1/menus | `system:menu:create` | 200 | 创建成功并返回 menuId |
| TC-20-10 | PUT /api/v1/menus/{id} | `system:menu:update` | 200 | 更新成功，名称/排序生效 |
| TC-20-11 | DELETE /api/v1/menus/{id} | `system:menu:delete` | 200 | 删除成功后列表不再可见 |
| TC-20-12 | GET /api/v1/menus | `system:menu:list` | 200 | tenant A 看不到 tenant B 菜单 |
| TC-20-13 | GET /api/v1/menus | `system:menu:list` | 200 | tenant B 看不到 tenant A 菜单 |
| TC-20-14 | GET /api/v1/menus/tree | `system:menu:list` | 200 | 根节点 `parentId=0` 出现在首层 |
| TC-20-15 | POST /api/v1/menus | `system:menu:create` | 200 | 新建菜单 permission 字段持久化 |

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V022__create_sys_menu.sql
ljwx-platform-app/src/main/resources/db/migration/V023__seed_sys_menu.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysMenu.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysMenuMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/MenuAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/MenuController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/MenuCreateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/MenuUpdateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/MenuVO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/MenuTreeVO.java
ljwx-platform-app/src/main/resources/mapper/SysMenuMapper.xml
ljwx-platform-admin/src/api/menu.ts
ljwx-platform-admin/src/stores/menu.ts
ljwx-platform-admin/src/views/system/menu/index.vue
```

## 验收条件

1. V022 含 7 列审计字段，无 IF NOT EXISTS
2. GET /api/v1/menus/tree 返回嵌套树结构
3. MenuController 所有方法有 @PreAuthorize
4. 编译通过，type-check 通过
