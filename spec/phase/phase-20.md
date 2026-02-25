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
| 前置依赖 | Phase 19 (部门管理) |
| 预计文件数 | 14 |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Menus 路由
- `spec/04-database.md` — sys_menu 表结构
- `spec/01-constraints.md` — §TypeScript 约束、§审计字段
- `spec/08-output-rules.md`

## 数据库设计

### 表结构

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键 |
| parent_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 父节点 ID，0 = 根节点 |
| name | VARCHAR(64) | NOT NULL | 菜单名称 |
| path | VARCHAR(200) | NOT NULL, DEFAULT '' | 路由路径 |
| component | VARCHAR(200) | NOT NULL, DEFAULT '' | 前端组件路径 |
| icon | VARCHAR(100) | NOT NULL, DEFAULT '' | 图标 |
| sort | INT | NOT NULL, DEFAULT 0, INDEX | 排序 |
| menu_type | SMALLINT | NOT NULL, DEFAULT 0 | 菜单类型：0=目录 1=菜单 2=按钮 |
| permission | VARCHAR(100) | NOT NULL, DEFAULT '' | 权限字符串 |
| visible | SMALLINT | NOT NULL, DEFAULT 1 | 显示状态：1=显示 0=隐藏 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 租户 ID（框架自动填充） |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除标记 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁版本号 |

### 索引

- PRIMARY KEY (id)
- INDEX idx_menu_tenant_parent (tenant_id, parent_id) WHERE deleted = FALSE
- INDEX idx_menu_tenant_sort (tenant_id, sort) WHERE deleted = FALSE

### Flyway 文件

- **V022__create_sys_menu.sql**: 创建 sys_menu 表及索引
- **V023__seed_sys_menu.sql**: 插入系统管理目录及用户/角色/菜单/部门/字典/配置/日志/文件/公告子菜单，permission 对应已有 RBAC 字符串
- 命名规则: Phase 编号对应 Flyway 版本号
- 必须包含: 表创建、索引创建、注释
- 禁止包含: `IF NOT EXISTS`

## API 定义

### 端点列表

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/menus | system:menu:list | — | Result<List<MenuVO>> | 查询菜单列表（平铺） |
| GET | /api/v1/menus/tree | system:menu:list | — | Result<List<MenuTreeVO>> | 查询菜单树（嵌套） |
| GET | /api/v1/menus/{id} | system:menu:detail | — | Result<MenuVO> | 查询菜单详情 |
| POST | /api/v1/menus | system:menu:create | MenuCreateDTO | Result<Long> | 创建菜单 |
| PUT | /api/v1/menus/{id} | system:menu:update | MenuUpdateDTO | Result<Void> | 更新菜单 |
| DELETE | /api/v1/menus/{id} | system:menu:delete | — | Result<Void> | 删除菜单（软删除） |

### 通用约定

- 所有端点前缀: `/api/v1/`
- 响应统一包装: `Result<T>`（code, message, data, traceId）
- 认证: Bearer Token（Header: Authorization）
- 未认证: 401，无权限: 403，参数错误: 400，业务异常: 500 + 业务错误码

## 类设计

### Entity

```java
// com.ljwx.platform.app.domain.entity.SysMenu
@Data
@EqualsAndHashCode(callSuper = true)
public class SysMenu extends BaseEntity {
    private Long id;
    private Long parentId;        // 父节点 ID，0 = 根节点
    private String name;          // 菜单名称
    private String path;          // 路由路径
    private String component;     // 前端组件路径
    private String icon;          // 图标
    private Integer sort;         // 排序
    private Integer menuType;     // 菜单类型：0=目录 1=菜单 2=按钮
    private String permission;    // 权限字符串
    private Integer visible;      // 显示状态：1=显示 0=隐藏

    // tenant_id, created_by, created_time, updated_by, updated_time, deleted, version
    // 由 BaseEntity 和 MyBatis-Plus 自动填充，此处不声明
}
```

### DTO

```java
// MenuCreateDTO — 创建请求
// 字段: parentId(@NotNull), name(@NotBlank), path, component, icon,
//       sort, menuType(@NotNull), permission, visible
// 禁止包含: id, tenantId, createdBy, createdTime, updatedBy, updatedTime, deleted, version

// MenuUpdateDTO — 更新请求
// 字段: 同 CreateDTO，所有字段可选（Partial Update）
// 禁止包含: id, tenantId, createdBy, createdTime, updatedBy, updatedTime, deleted, version
```

### VO

```java
// MenuVO — 列表响应（平铺）
// 字段: id, parentId, name, path, component, icon, sort, menuType,
//       permission, visible, createdTime, updatedTime
// 禁止包含: tenantId, deleted, createdBy, updatedBy, version

// MenuTreeVO — 树查询响应（嵌套）
// 字段: id, parentId, name, path, component, icon, sort, menuType,
//       permission, visible, children(List<MenuTreeVO>)
// 禁止包含: tenantId, deleted, createdBy, updatedBy, createdTime, updatedTime, version
```

### Mapper

```java
// SysMenuMapper extends BaseMapper<SysMenu>
// SysMenuMapper.xml — 自定义 SQL（如需要）
```

### Service

```java
// MenuAppService — 应用服务
// 方法: listMenus(), getMenuTree(), getMenu(id), createMenu(dto),
//       updateMenu(id, dto), deleteMenu(id)
// 职责: CRUD + 树形构建（内存构建，不使用递归 SQL）
```

## 业务逻辑

### 查询列表
1. 调用 `menuMapper.selectAll()` 查询当前租户所有菜单（TenantLineInterceptor 自动注入 tenant_id 条件）
2. 转换为 MenuVO 列表返回

### 查询树
1. 调用 `menuMapper.selectAll()` 查询当前租户所有菜单
2. 转换为 MenuTreeVO 列表
3. 在内存中构建树结构（parentId=0 为根节点，递归构建子节点）
4. 按 sort 字段排序
5. 返回树形结构

### 查询详情
1. 调用 `menuMapper.selectById(id)` 查询菜单
2. 若不存在，抛出 BusinessException(ErrorCode.MENU_NOT_FOUND)
3. 转换为 MenuVO 返回

### 创建
1. 校验 parentId 对应的父菜单存在且属于当前租户（parentId=0 时跳过）
2. 生成雪花 ID
3. 设置 tenantId（从 CurrentTenantHolder 获取）
4. 保存到数据库
5. 返回菜单 ID

### 更新
1. 校验菜单存在且属于当前租户
2. 更新字段（仅更新 DTO 中非 null 的字段）
3. 保存到数据库

### 删除
1. 校验菜单存在且属于当前租户
2. 校验该菜单下无子菜单（有则拒绝删除，返回业务异常）
3. 逻辑删除（MyBatis-Plus @TableLogic 自动处理，设置 deleted=TRUE）

## 测试用例

### 安全测试（Security）

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-20-01 | 未认证访问列表 | GET /api/v1/menus (无 Token) | 401 | P0 |
| TC-20-02 | 无权限访问列表 | GET /api/v1/menus (无 system:menu:list) | 403 | P0 |
| TC-20-03 | 无权限创建菜单 | POST /api/v1/menus (无 system:menu:create) | 403 | P0 |
| TC-20-04 | 无权限更新菜单 | PUT /api/v1/menus/{id} (无 system:menu:update) | 403 | P0 |
| TC-20-05 | 无权限删除菜单 | DELETE /api/v1/menus/{id} (无 system:menu:delete) | 403 | P0 |

### CRUD 测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-20-06 | 正常查询列表 | GET /api/v1/menus | 200, 返回数组结构 | P0 |
| TC-20-07 | 正常查询树 | GET /api/v1/menus/tree | 200, 返回树形数组 | P0 |
| TC-20-08 | 正常查询详情 | GET /api/v1/menus/{id} | 200, 字段完整 | P0 |
| TC-20-09 | 正常创建菜单 | POST /api/v1/menus | 200, 返回菜单 ID | P0 |
| TC-20-10 | 正常更新菜单 | PUT /api/v1/menus/{id} | 200, 更新成功 | P0 |
| TC-20-11 | 正常删除菜单 | DELETE /api/v1/menus/{id} | 200, 删除后列表不可见 | P0 |

### 业务规则测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-20-12 | 租户隔离（租户 A） | 租户 A 查询，不返回租户 B 数据 | 仅返回租户 A 菜单 | P0 |
| TC-20-13 | 租户隔离（租户 B） | 租户 B 查询，不返回租户 A 数据 | 仅返回租户 B 菜单 | P0 |
| TC-20-14 | 树根节点验证 | GET /api/v1/menus/tree | 根节点 parentId=0 出现在首层 | P0 |
| TC-20-15 | 软删除验证 | 删除后数据库 deleted=TRUE，API 查询不返回 | 符合预期 | P0 |
| TC-20-16 | 删除有子菜单的菜单 | DELETE 含子菜单的父菜单 | 400/业务异常 | P0 |
| TC-20-17 | 查询不存在的菜单 | GET /api/v1/menus/{不存在的id} | 404/业务异常 | P1 |
| TC-20-18 | 创建菜单 permission 持久化 | POST 创建菜单，再查询 | permission 字段正确保存 | P1 |

### 参数校验测试

| ID | 场景 | 方法 | 期望 | 优先级 |
|----|------|------|------|--------|
| TC-20-19 | parentId 为空 | POST parentId=null | 400 | P1 |
| TC-20-20 | name 为空 | POST name=null | 400 | P1 |
| TC-20-21 | menuType 为空 | POST menuType=null | 400 | P1 |
| TC-20-22 | name 超长 | POST name=65字符 | 400 | P2 |

## 验收条件映射

| 验收条件 | 来源 | 测试用例 | Gate 维度 |
|---------|------|----------|----------|
| AC-01 | F-020 | TC-20-01 | R05 |
| AC-02 | F-020 | TC-20-02, TC-20-03, TC-20-04, TC-20-05 | R04, R05 |
| AC-03 | F-020 | TC-20-09, TC-20-06 | R09 |
| AC-04 | F-020 | TC-20-12, TC-20-13 | R03 |
| AC-05 | F-020 | TC-20-11, TC-20-15 | R07, R09 |

## 预期生成文件

| 文件路径 | 类型 | Gate 关联 |
|---------|------|----------|
| db/migration/V022__create_sys_menu.sql | Migration | R02 |
| db/migration/V023__seed_sys_menu.sql | Migration | R02 |
| .../entity/SysMenu.java | Entity | R07 |
| .../mapper/SysMenuMapper.java | Mapper | R06 |
| .../mapper/xml/SysMenuMapper.xml | Mapper XML | R05 |
| .../dto/MenuCreateDTO.java | DTO | R03 |
| .../dto/MenuUpdateDTO.java | DTO | R03 |
| .../vo/MenuVO.java | VO | R03 |
| .../vo/MenuTreeVO.java | VO | R03 |
| .../appservice/MenuAppService.java | Service | R06 |
| .../controller/MenuController.java | Controller | R04 |
| src/test/java/.../controller/MenuControllerTest.java | Test | R09 |
| ljwx-platform-admin/src/api/menu.ts | Frontend API | — |
| ljwx-platform-admin/src/stores/menu.ts | Frontend Store | — |
| ljwx-platform-admin/src/views/system/menu/index.vue | Frontend View | — |

## 验收条件

1. V022 含 7 列审计字段，无 IF NOT EXISTS
2. GET /api/v1/menus/tree 返回嵌套树结构
3. MenuController 所有方法有 @PreAuthorize
4. DTO 中不包含 tenantId、deleted、审计列
5. 编译通过，type-check 通过
6. 所有 P0 测试用例通过

## 关键约束

- sys_menu 含 7 列审计字段，无 IF NOT EXISTS
- MenuController 每个方法有 @PreAuthorize
- 前端无 any，strict: true
- DTO 禁止包含 tenantId
- 树形构建在内存中完成，不使用递归 SQL
