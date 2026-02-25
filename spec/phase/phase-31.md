---
phase: 31
title: "Frontend Permission Directive and Enhancement"
targets:
  backend: false
  frontend: true
depends_on: [30]
bundle_with: []
scope:
  - "ljwx-platform-admin/src/directives/permission.ts"
  - "ljwx-platform-admin/src/directives/index.ts"
  - "ljwx-platform-admin/src/main.ts"
  - "ljwx-platform-admin/src/composables/usePermission.ts"
  - "ljwx-platform-admin/src/views/monitor/dataChangeLog/index.vue"
  - "ljwx-platform-admin/src/api/dataChangeLog.ts"
  - "ljwx-platform-admin/src/router/index.ts"
---
# Phase 31: Frontend Permission Directive & Enhancement

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/02-frontend.md` — §权限控制、§路由
- `spec/08-output-rules.md`

## 任务

### 1. v-permission 自定义指令

**directives/permission.ts**：

```typescript
import type { Directive } from 'vue'
import { useUserStore } from '@/stores/user'

export const vPermission: Directive<HTMLElement, string | string[]> = {
  mounted(el, binding) {
    const userStore = useUserStore()
    const required = Array.isArray(binding.value) ? binding.value : [binding.value]
    const hasPermission = required.some(p => userStore.permissions.includes(p))
    if (!hasPermission) {
      el.parentNode?.removeChild(el)
    }
  }
}
```

**directives/index.ts**：统一导出所有指令，供 `main.ts` 批量注册。

**main.ts**：注册 `v-permission` 指令（`app.directive('permission', vPermission)`）。

### 2. usePermission composable 增强

**composables/usePermission.ts**（已存在，增强）：
- 增加 `hasAnyPermission(permissions: string[]): boolean` — 满足任意一个权限
- 增加 `hasAllPermissions(permissions: string[]): boolean` — 满足全部权限
- 增加 `hasRole(role: string): boolean` — 角色检查（从 userStore 读取）

### 3. 数据变更日志前端页面

**api/dataChangeLog.ts**：
```typescript
import request from '@/api/request'
import type { PageResult } from '@ljwx/shared'

export interface DataChangeLogVO {
  id: number
  tableName: string
  recordId: number
  fieldName: string
  oldValue: string
  newValue: string
  operateType: string
  createdBy: string
  createdTime: string
}

export interface DataChangeLogQuery {
  tableName?: string
  recordId?: number
  startTime?: string
  endTime?: string
  pageNum: number
  pageSize: number
}

export function getDataChangeLogs(params: DataChangeLogQuery): Promise<PageResult<DataChangeLogVO>> {
  return request.get('/data-change-logs', { params })
}
```

**views/monitor/dataChangeLog/index.vue**：
- 搜索栏：表名、记录 ID、时间范围
- 表格：表名、记录 ID、字段名、变更前值、变更后值、操作类型、操作人、操作时间
- 分页

### 4. 路由注册

在 `router/index.ts` 中为 `dataChangeLog` 页面添加路由：
```typescript
{
  path: 'data-change-log',
  name: 'DataChangeLog',
  component: () => import('@/views/monitor/dataChangeLog/index.vue'),
  meta: { title: '数据变更日志', permission: 'system:audit:list' }
}
```

## 关键约束

- v-permission 指令从 userStore 读取权限列表，不发起额外 API 请求
- 禁止 `any` 类型
- DataChangeLogVO 中无 tenantId 字段（前端禁止传递/展示 tenantId）
- 路由按 vue-router v5 API 写

## Phase-Local Manifest

```
ljwx-platform-admin/src/directives/permission.ts
ljwx-platform-admin/src/directives/index.ts
ljwx-platform-admin/src/main.ts
ljwx-platform-admin/src/composables/usePermission.ts
ljwx-platform-admin/src/views/monitor/dataChangeLog/index.vue
ljwx-platform-admin/src/api/dataChangeLog.ts
ljwx-platform-admin/src/router/index.ts
```

## 验收条件

1. v-permission 指令正确隐藏无权限元素
2. usePermission.ts 无 `any` 类型
3. DataChangeLog 页面 type-check 通过
4. 路由使用 vue-router v5 API
5. type-check 全部通过

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-31-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-31-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-31-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-31-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-31-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-31-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-31-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-31-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-31-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-31-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
