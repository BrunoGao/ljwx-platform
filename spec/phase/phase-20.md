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
# Phase 20 — 菜单管理与动态路由 (Menu Management and Dynamic Routes)

| 项目 | 值 |
|-----|---|
| Phase | 20 |
| 模块 | ljwx-platform-app (后端), ljwx-platform-admin (前端) |
| Feature | F-020 (菜单管理) |
| 前置依赖 | Phase 19 (Interim Gate and Docs) |
| 测试契约 | `spec/tests/phase-20-menu.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §sys_menu 表结构
- `spec/03-api.md` — §Menus 路由
- `spec/01-constraints.md` — §审计字段、§TypeScript 约束
- `spec/08-output-rules.md`

---

## 数据库契约

### 表结构：sys_menu

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| parent_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 父节点 ID，0 = 根节点 |
| name | VARCHAR(64) | NOT NULL | 菜单名称 |
| path | VARCHAR(200) | NOT NULL, DEFAULT '' | 路由路径 |
| component | VARCHAR(200) | NOT NULL, DEFAULT '' | 前端组件路径 |
| icon | VARCHAR(100) | NOT NULL, DEFAULT '' | 图标 |
| sort | INT | NOT NULL, DEFAULT 0 | 排序权重 |
| menu_type | SMALLINT | NOT NULL, DEFAULT 0 | 0=目录 1=菜单 2=按钮 |
| permission | VARCHAR(100) | NOT NULL, DEFAULT '' | 权限字符串 |
| visible | SMALLINT | NOT NULL, DEFAULT 1 | 1=显示 0=隐藏 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**：`idx_menu_tenant_parent(tenant_id, parent_id)`、`idx_menu_tenant_sort(tenant_id, sort)`，条件 `WHERE deleted = FALSE`

### Flyway 文件

| 文件 | 内容 |
|------|------|
| V022__create_sys_menu.sql | 建表 + 索引 |
| V023__seed_sys_menu.sql | 插入系统管理目录及子菜单（user/role/menu/dept/dict/config/log/file/notice），permission 对应已有 RBAC 字符串 |

禁止：`IF NOT EXISTS`、建表文件中混 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/menus | system:menu:list | — | Result<List\<MenuVO\>> | 平铺列表 |
| GET | /api/v1/menus/tree | system:menu:list | — | Result<List\<MenuTreeVO\>> | 嵌套树 |
| GET | /api/v1/menus/{id} | system:menu:detail | — | Result\<MenuVO\> | 详情 |
| POST | /api/v1/menus | system:menu:create | MenuCreateDTO | Result\<Long\> | 创建 |
| PUT | /api/v1/menus/{id} | system:menu:update | MenuUpdateDTO | Result\<Void\> | 更新 |
| DELETE | /api/v1/menus/{id} | system:menu:delete | — | Result\<Void\> | 软删除 |

---

## DTO / VO 契约

### MenuCreateDTO（创建请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| parentId | Long | @NotNull | 父节点 ID（0=根节点） |
| name | String | @NotBlank, max=64 | 菜单名称 |
| path | String | — | 路由路径 |
| component | String | — | 前端组件路径 |
| icon | String | — | 图标 |
| sort | Integer | — | 排序（默认 0） |
| menuType | Integer | @NotNull | 0=目录 1=菜单 2=按钮 |
| permission | String | — | 权限字符串 |
| visible | Integer | — | 1=显示 0=隐藏（默认 1） |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### MenuUpdateDTO（更新请求）

与 MenuCreateDTO 相同字段，全部可选（Partial Update）。**禁止字段**同上。

### MenuVO（平铺响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| parentId | Long | 父节点 |
| name | String | 菜单名称 |
| path | String | 路由路径 |
| component | String | 组件路径 |
| icon | String | 图标 |
| sort | Integer | 排序 |
| menuType | Integer | 菜单类型 |
| permission | String | 权限字符串 |
| visible | Integer | 显示状态 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`version`

### MenuTreeVO（树形响应）

MenuVO 所有字段，去掉 `createdTime`/`updatedTime`，增加：

| 字段 | 类型 | 说明 |
|------|------|------|
| children | List\<MenuTreeVO\> | 子节点（内存构建） |

---

## 实体 / 服务契约

```
Entity  : SysMenu extends BaseEntity
          业务字段见 DB 表结构，审计字段由 BaseEntity 继承，勿重复声明

Mapper  : SysMenuMapper（自定义接口，不继承 BaseMapper）
            @Mapper interface with：
            - selectAll()             → 当前租户全量（TenantLineInterceptor 注入）
            - selectById(Long)        → 单条，含 deleted=FALSE 过滤
            - insert(SysMenu)         → 含审计字段
            - updateById(SysMenu)     → 含乐观锁 version 校验
            - countByParentId(Long)   → 子菜单数，用于删除前校验
            - deleteById(Long)        → 软删除（deleted=TRUE）
          配套 SysMenuMapper.xml（全量自定义 SQL）

Service : MenuAppService（应用服务，非 IService）
          方法: listMenus(), getMenuTree(), getMenu(id),
                createMenu(dto), updateMenu(id, dto), deleteMenu(id)
```

---

## 业务规则

- **BL-20-01**：创建时 parentId ≠ 0 → 校验父菜单存在且属于当前租户，否则拒绝
- **BL-20-02**：删除时 → 校验菜单下无子菜单，有则抛出 `BusinessException(MENU_HAS_CHILDREN)`
- **BL-20-03**：软删除 → 调用 MyBatis-Plus `@TableLogic`，`deleted=TRUE`，后续查询自动过滤
- **BL-20-04**：`tenant_id` 由 `TenantLineInterceptor` 自动注入，无需代码显式传递
- **BL-20-05**：getMenuTree() → 内存构建树（parentId=0 为根节点），按 sort 升序排列

> 关于"内存建树 vs 递归 SQL"的取舍说明 → 见 `spec/adr/ADR-20-menu-tree.md`

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-20-menu.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-20-01 | 无 Token → 401 | P0 |
| TC-20-02 | 无权限 → 403（list/create/update/delete 各一条） | P0 |
| TC-20-03 | 正常 CRUD（create/list/tree/detail/update/delete） | P0 |
| TC-20-04 | 租户隔离（A 查不到 B 的数据） | P0 |
| TC-20-05 | 软删除（deleted=TRUE，查询不返回） | P0 |
| TC-20-06 | 删除含子菜单的父菜单 → 业务异常 | P0 |

---

## 验收条件

- **AC-01**：V022 含 7 列审计字段，无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize("hasAuthority('system:menu:...')")`
- **AC-03**：DTO 不含 `tenantId` 及其他禁止字段
- **AC-04**：GET /api/v1/menus/tree 返回嵌套树，根节点 parentId=0 在首层
- **AC-05**：软删除生效，`deleted=TRUE` 后 API 查询不返回
- **AC-06**：编译通过，前端 `type-check` 通过，所有 P0 用例通过

---

## 关键约束

- 禁止：`IF NOT EXISTS` · `tenantId` in DTO · `any` in TypeScript
- 权限格式：`hasAuthority('system:menu:{action}')` —— 无 ROLE_ 前缀
- 树形构建：在内存中完成，禁止使用递归 SQL（见 ADR-20）
- 前端版本号：仅 `~`（tilde），禁止 `^`（caret）

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-20-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-20-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-20-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-20-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-20-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-20-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-20-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-20-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-20-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-20-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
