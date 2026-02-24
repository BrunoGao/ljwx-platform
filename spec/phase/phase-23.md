---
phase: 23
title: "Admin Frontend Pages Batch 2"
targets:
  backend: false
  frontend: true
depends_on: [22]
bundle_with: []
scope:
  - "ljwx-platform-admin/src/api/dept.ts"
  - "ljwx-platform-admin/src/api/profile.ts"
  - "ljwx-platform-admin/src/api/loginLog.ts"
  - "ljwx-platform-admin/src/api/onlineUser.ts"
  - "ljwx-platform-admin/src/views/system/dept/index.vue"
  - "ljwx-platform-admin/src/views/system/menu/index.vue"
  - "ljwx-platform-admin/src/views/system/profile/index.vue"
  - "ljwx-platform-admin/src/views/monitor/loginLog/index.vue"
  - "ljwx-platform-admin/src/views/monitor/onlineUser/index.vue"
---
# Phase 23: Admin Frontend Pages Batch 2

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Menus、§Depts、§Profile、§LoginLog、§OnlineUsers
- `spec/01-constraints.md` — §TypeScript 约束
- `spec/08-output-rules.md`

## 任务

以下前端页面均遵循已有页面风格（参考 Phase 13 生成的 views/system/ 下的页面）。

### API 层

- `src/api/dept.ts` — GET /api/v1/depts, /depts/tree, POST, PUT, DELETE
- `src/api/profile.ts` — GET/PUT /api/v1/profile, PUT /api/v1/profile/password
- `src/api/loginLog.ts` — GET /api/v1/login-logs
- `src/api/onlineUser.ts` — GET /api/v1/online-users, DELETE /api/v1/online-users/{tokenId}

### 视图页面

**system/dept/index.vue** — 部门树形管理
- el-tree 展示部门树
- 右侧表单新增/编辑部门
- 删除确认

**system/menu/index.vue** — 菜单树形管理
- el-table 树形模式展示菜单
- 新增/编辑弹窗（含菜单类型：目录/菜单/按钮）
- 图标选择器（使用 @element-plus/icons-vue）

**system/profile/index.vue** — 个人中心
- 左侧：头像 + 基本信息展示
- 右侧 Tabs：基本信息修改 / 修改密码

**monitor/loginLog/index.vue** — 登录日志
- 搜索（用户名、状态、时间范围）+ 表格 + 分页
- 状态列：成功（绿）/ 失败（红）

**monitor/onlineUser/index.vue** — 在线用户
- 表格展示在线用户列表
- 强制下线按钮（带确认）

## 关键约束

- 无 TypeScript any
- 所有 API 调用使用 `@ljwx/shared` 中的类型（如无对应类型则在 api 文件中本地定义）
- 路由注册到已有 router/index.ts（在 scope 外，通过 PATCH 方式最小化修改）

## Phase-Local Manifest

```
ljwx-platform-admin/src/api/dept.ts
ljwx-platform-admin/src/api/profile.ts
ljwx-platform-admin/src/api/loginLog.ts
ljwx-platform-admin/src/api/onlineUser.ts
ljwx-platform-admin/src/views/system/dept/index.vue
ljwx-platform-admin/src/views/system/menu/index.vue
ljwx-platform-admin/src/views/system/profile/index.vue
ljwx-platform-admin/src/views/monitor/loginLog/index.vue
ljwx-platform-admin/src/views/monitor/onlineUser/index.vue
```

## 验收条件

1. pnpm run type-check 通过
2. 无 TypeScript any
3. 所有页面有搜索 + 表格 + 分页（列表页）或完整表单（详情页）
