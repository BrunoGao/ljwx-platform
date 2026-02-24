---
phase: 21
title: "Department Management and Data Scope"
targets:
  backend: true
  frontend: true
depends_on: [20]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V024__create_sys_dept.sql"
  - "ljwx-platform-app/src/main/resources/db/migration/V025__seed_sys_dept.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDept.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDeptMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/DeptAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/DeptController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/DeptCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/DeptUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/DeptVO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/DeptTreeVO.java"
  - "ljwx-platform-app/src/main/resources/mapper/SysDeptMapper.xml"
  - "ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/DataScopeInterceptor.java"
  - "ljwx-platform-admin/src/api/dept.ts"
  - "ljwx-platform-admin/src/views/system/dept/index.vue"
---
# Phase 21: Department Management & Data Scope

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Depts 路由
- `spec/04-database.md` — sys_dept 表结构
- `spec/01-constraints.md` — §DAG 依赖、§审计字段
- `spec/08-output-rules.md`

## 任务

### 后端

**表 sys_dept**（V024）：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| parent_id | BIGINT NOT NULL DEFAULT 0 | 父部门，0 = 根 |
| name | VARCHAR(64) NOT NULL | 部门名称 |
| sort | INT NOT NULL DEFAULT 0 | 排序 |
| leader | VARCHAR(64) NOT NULL DEFAULT '' | 负责人 |
| phone | VARCHAR(20) NOT NULL DEFAULT '' | 联系电话 |
| email | VARCHAR(100) NOT NULL DEFAULT '' | 邮箱 |
| status | SMALLINT NOT NULL DEFAULT 1 | 1=正常 0=停用 |
| + 7 列审计字段 | | |

V025 种子数据：插入默认根部门（总公司）及示例子部门。

API：`/api/v1/depts`

| 方法 | 路径 | 权限 |
|------|------|------|
| GET | /api/v1/depts | `system:dept:list` |
| GET | /api/v1/depts/tree | `system:dept:list`（树形） |
| GET | /api/v1/depts/{id} | `system:dept:detail` |
| POST | /api/v1/depts | `system:dept:create` |
| PUT | /api/v1/depts/{id} | `system:dept:update` |
| DELETE | /api/v1/depts/{id} | `system:dept:delete` |

**DataScopeInterceptor**（ljwx-platform-data 模块）：
- MyBatis Interceptor，拦截 query 操作
- 从 SecurityContext 读取当前用户的 data_scope（全部/本租户/本部门及下级/本部门/仅本人）
- 自动追加 dept_id IN (...) 条件
- 注意：data 模块禁止 import security 包，通过 ThreadLocal 传递 data_scope 值

### 前端

- `src/api/dept.ts` — 调用上述接口
- `src/views/system/dept/index.vue` — 树形表格，支持新增/编辑/删除

## 关键约束

- DataScopeInterceptor 在 data 模块，禁止 import com.ljwx.platform.security.*
- data_scope 通过 ThreadLocal（在 web 模块的拦截器中设置）传递
- sys_dept 含 7 列审计字段

## Phase-Local Manifest

```
ljwx-platform-app/src/main/resources/db/migration/V024__create_sys_dept.sql
ljwx-platform-app/src/main/resources/db/migration/V025__seed_sys_dept.sql
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/SysDept.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/SysDeptMapper.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/DeptAppService.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/DeptController.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/DeptCreateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/DeptUpdateDTO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/DeptVO.java
ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/DeptTreeVO.java
ljwx-platform-app/src/main/resources/mapper/SysDeptMapper.xml
ljwx-platform-data/src/main/java/com/ljwx/platform/data/interceptor/DataScopeInterceptor.java
ljwx-platform-admin/src/api/dept.ts
ljwx-platform-admin/src/views/system/dept/index.vue
```

## 验收条件

1. V024 含 7 列审计字段，无 IF NOT EXISTS
2. DataScopeInterceptor 无 security 包 import（DAG 合规）
3. DeptController 所有方法有 @PreAuthorize
4. 编译通过，type-check 通过
