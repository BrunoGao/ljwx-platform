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

## Overview

| 项目 | 内容 |
|------|------|
| Phase | 31 |
| 模块 | ljwx-platform-admin |
| Feature | v-permission 指令、usePermission 增强、数据变更日志前端页面 |
| 前置依赖 | Phase 30 |
| 测试契约 | N/A — 纯前端，验证方式：pnpm run type-check 通过 |

## 读取清单
- `CLAUDE.md`（自动加载）
- `spec/02-frontend.md` — §权限控制、§路由（如无此文件，跳过）
- `spec/08-output-rules.md`

## 组件契约

| 文件 | 核心行为 |
|------|----------|
| directives/permission.ts | `Directive<HTMLElement, string \| string[]>`，mounted 时检查 userStore.permissions，无权限则 el.parentNode.removeChild(el) |
| directives/index.ts | 统一导出所有指令，含 vPermission |
| main.ts | 注册 v-permission 指令：`app.directive('permission', vPermission)` |
| composables/usePermission.ts | 增加 `hasAnyPermission(permissions: string[]): boolean`、`hasAllPermissions(permissions: string[]): boolean`、`hasRole(role: string): boolean` |
| api/dataChangeLog.ts | 定义 DataChangeLogVO / DataChangeLogQuery 接口，实现 `getDataChangeLogs` 函数 |
| views/monitor/dataChangeLog/index.vue | 搜索栏（tableName/recordId/时间范围）+ 表格 + 分页 |
| router/index.ts | 添加 data-change-log 路由，meta: `{ title: '数据变更日志', permission: 'system:audit:list' }` |

## DataChangeLogVO 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| tableName | string | 目标表名 |
| recordId | number | 被变更记录 ID |
| fieldName | string | 变更字段名 |
| oldValue | string | 变更前值 |
| newValue | string | 变更后值 |
| operateType | string | UPDATE / DELETE |
| createdBy | number | 操作人 |
| createdTime | string | 操作时间 |

> 注：DataChangeLogVO 中不包含 tenantId 字段（硬规则：前端禁止传递 tenantId）

## 业务规则

- **BL-31-01**：v-permission 指令从 `userStore.permissions` 读取权限列表，不发起额外 API 请求，避免性能损耗
- **BL-31-02**：mounted 时若当前用户不具备所需权限，执行 `el.parentNode?.removeChild(el)` 移除 DOM 元素
- **BL-31-03**：数据变更日志路由 meta.permission 设置为 `'system:audit:list'`，路由守卫按此值进行权限校验

> 本 Phase 为纯前端，验证方式：pnpm run type-check 通过，无 TypeScript any

## 关键约束

- v-permission 指令禁止 any 类型，从 userStore 读取权限，不发起额外 API 请求
- usePermission.ts 全部方法返回类型明确，禁止 any
- DataChangeLogVO 中无 tenantId 字段
- router/index.ts 按 vue-router v5 API 写（禁止按 v4 经验写 createRouter）
- directives/index.ts 统一导出，main.ts 集中注册

## 验收条件

1. v-permission 指令正确隐藏无权限元素（DOM removeChild）
2. usePermission.ts 无 any 类型，新增三个方法签名明确
3. DataChangeLog 页面 type-check 通过
4. router/index.ts 使用 vue-router v5 API
5. pnpm run type-check 全部通过，无 TypeScript any
