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
# Phase 21 — Department Management & Data Scope

| 项目 | 值 |
|-----|---|
| Phase | 21 |
| 模块 | ljwx-platform-app (后端), ljwx-platform-data (拦截器), ljwx-platform-admin (前端) |
| 前置依赖 | Phase 20 (Menu Management) |
| 测试契约 | `spec/tests/phase-21-dept.tests.yml` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §sys_dept 表结构
- `spec/03-api.md` — §Depts 路由
- `spec/01-constraints.md` — §DAG 依赖、§审计字段
- `spec/08-output-rules.md`

---

## 数据库契约

### 表结构：sys_dept

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| parent_id | BIGINT | NOT NULL, DEFAULT 0 | 父部门 ID，0=根部门 |
| name | VARCHAR(64) | NOT NULL | 部门名称 |
| sort | INT | NOT NULL, DEFAULT 0 | 排序号 |
| leader | VARCHAR(64) | NOT NULL, DEFAULT '' | 负责人 |
| phone | VARCHAR(20) | NOT NULL, DEFAULT '' | 联系电话 |
| email | VARCHAR(100) | NOT NULL, DEFAULT '' | 邮箱 |
| status | SMALLINT | NOT NULL, DEFAULT 1 | 1=正常 0=停用 |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

> 审计字段（最后 7 列）由 BaseEntity 自动管理，禁止在 DTO 中声明。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V024__create_sys_dept.sql` | 建表 + 索引 |
| `V025__seed_sys_dept.sql` | 初始数据（根部门 + 示例子部门） |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/depts | system:dept:list | — | Result<List<DeptVO>> | 查询平铺列表 |
| GET | /api/v1/depts/tree | system:dept:list | — | Result<List<DeptTreeVO>> | 查询树形结构 |
| GET | /api/v1/depts/{id} | system:dept:detail | — | Result<DeptVO> | 查询详情 |
| POST | /api/v1/depts | system:dept:create | DeptCreateDTO | Result<Long> | 创建部门 |
| PUT | /api/v1/depts/{id} | system:dept:update | DeptUpdateDTO | Result<Void> | 更新部门 |
| DELETE | /api/v1/depts/{id} | system:dept:delete | — | Result<Void> | 删除（软删） |

---

## DTO / VO 契约

### DeptCreateDTO（创建请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| parentId | Long | @NotNull | 父部门 ID，0=根 |
| name | String | @NotBlank, @Size(max=64) | 部门名称 |
| sort | Integer | — | 排序号 |
| leader | String | @Size(max=64) | 负责人 |
| phone | String | @Size(max=20) | 联系电话 |
| email | String | @Email, @Size(max=100) | 邮箱 |
| status | Integer | — | 1=正常 0=停用 |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### DeptUpdateDTO（更新请求）

与 CreateDTO 相同字段，全部可选（Partial Update）。**禁止字段**同上。

### DeptVO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| parentId | Long | 父部门 ID |
| name | String | 部门名称 |
| sort | Integer | 排序号 |
| leader | String | 负责人 |
| phone | String | 联系电话 |
| email | String | 邮箱 |
| status | Integer | 状态 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`version`

### DeptTreeVO（树形响应）

继承 DeptVO，增加：

| 字段 | 类型 | 说明 |
|------|------|------|
| children | List<DeptTreeVO> | 子部门列表 |

---

## 实体 / 服务契约

```
Entity  : SysDept extends BaseEntity
          业务字段见上表，审计字段由 BaseEntity 继承，勿重复声明

Mapper  : SysDeptMapper extends BaseMapper<SysDept>
          自定义 SQL 在 SysDeptMapper.xml

Service : DeptAppService（非 IService，应用服务层）
          方法: listDepts(), getDeptTree(), getDept(id), createDept(dto),
                updateDept(id, dto), deleteDept(id)
```

---

## 业务规则

> 格式：BL-21-{序号}：\[条件\] → \[动作\] → \[结果/异常\]

- **BL-21-01**：创建部门时 parentId 不存在 → 校验失败 → 抛出 `BusinessException(ErrorCode.PARENT_DEPT_NOT_FOUND)`
- **BL-21-02**：删除含子部门的父部门 → 拒绝删除 → 抛出 `BusinessException(ErrorCode.DEPT_HAS_CHILDREN)`
- **BL-21-03**：软删除生效 → 删除后 `deleted=TRUE`，API 查询不返回
- **BL-21-04**：TenantLineInterceptor 自动注入 tenant_id，租户间数据隔离
- **BL-21-05**：树形查询 `/depts/tree` → 内存递归建树（parentId=0 为根节点）

---

## DataScopeInterceptor（数据权限拦截器）

**位置**：`ljwx-platform-data` 模块

**功能**：MyBatis Interceptor，拦截 SELECT 语句，根据当前用户的数据权限范围自动追加 `dept_id IN (...)` 条件。

**数据权限范围**：
- 全部数据（不限制）
- 本租户数据（已由 TenantLineInterceptor 处理）
- 本部门及下级部门
- 仅本部门
- 仅本人

**关键约束**：
- data 模块**禁止 import security 包**（DAG 约束：data 不依赖 security）
- 数据权限范围通过 ThreadLocal 传递（在 web 模块的拦截器中设置）
- 从 `CurrentUserHolder`（core 模块）获取 userId 和 dataScope

---

## 前端契约

### API 层：`src/api/dept.ts`

```typescript
import request from '@/api/request'
import type { Result } from '@ljwx/shared'

export interface DeptVO {
  id: number
  parentId: number
  name: string
  sort: number
  leader: string
  phone: string
  email: string
  status: number
  createdTime: string
  updatedTime: string
}

export interface DeptTreeVO extends DeptVO {
  children?: DeptTreeVO[]
}

export interface DeptCreateDTO {
  parentId: number
  name: string
  sort?: number
  leader?: string
  phone?: string
  email?: string
  status?: number
}

export interface DeptUpdateDTO extends Partial<DeptCreateDTO> {}

export function getDepts(): Promise<DeptVO[]> {
  return request.get('/depts')
}

export function getDeptTree(): Promise<DeptTreeVO[]> {
  return request.get('/depts/tree')
}

export function getDept(id: number): Promise<DeptVO> {
  return request.get(`/depts/${id}`)
}

export function createDept(data: DeptCreateDTO): Promise<number> {
  return request.post('/depts', data)
}

export function updateDept(id: number, data: DeptUpdateDTO): Promise<void> {
  return request.put(`/depts/${id}`, data)
}

export function deleteDept(id: number): Promise<void> {
  return request.delete(`/depts/${id}`)
}
```

### 视图层：`src/views/system/dept/index.vue`

**功能**：
- 左侧：el-tree 展示部门树
- 右侧：表单（新增/编辑部门）
- 删除确认弹窗

**关键点**：
- 无 TypeScript `any`
- 使用 `@ljwx/shared` 中的类型
- 树形数据绑定 `node-key="id"`，`props="{ children: 'children', label: 'name' }"`

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-21-dept.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-21-01 | 无 Token → 401 | P0 |
| TC-21-02 | 无权限 → 403 | P0 |
| TC-21-03 | 正常 CRUD | P0 |
| TC-21-04 | 树形查询返回嵌套结构 | P0 |
| TC-21-05 | 租户隔离 | P0 |
| TC-21-06 | 软删除 | P0 |
| TC-21-07 | 删除含子部门的父部门 → 400 | P0 |
| TC-21-08 | parentId 不存在 → 400 | P0 |

---

## 验收条件

- **AC-01**：V024/V025 含 7 列审计字段，无 `IF NOT EXISTS`
- **AC-02**：DeptController 所有方法有 `@PreAuthorize("hasAuthority('system:dept:...')")`
- **AC-03**：DTO 不含 `tenantId` 及其他禁止字段
- **AC-04**：租户隔离生效（tenant_id 由 Interceptor 注入）
- **AC-05**：软删除生效（`deleted=TRUE` 后 API 查询不返回）
- **AC-06**：DataScopeInterceptor 无 security 包 import（DAG 合规）
- **AC-07**：编译通过，前端 `type-check` 通过，所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT，禁止在 DTO 中声明
- 权限格式：`hasAuthority('system:dept:{action}')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · `tenantId` in DTO · `any` in TypeScript
- DAG 约束：data 模块禁止 import security 包
- 前端版本号：仅 `~`（tilde），禁止 `^`（caret）
