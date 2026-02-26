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
  - "ljwx-platform-admin/src/views/monitor/loginlog/index.vue"
  - "ljwx-platform-admin/src/views/monitor/onlineUser/index.vue"
---
# Phase 23 — Admin Frontend Pages Batch 2

| 项目 | 值 |
|-----|---|
| Phase | 23 |
| 模块 | ljwx-platform-admin（前端 only） |
| Feature | Dept / Menu / Profile / LoginLog / OnlineUser 前端页面 |
| 前置依赖 | Phase 22 (Profile Login Log and Online Users) |
| 测试契约 | N/A — 纯前端，验证方式：`pnpm run type-check` 通过，无 TypeScript `any` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Menus、§Depts、§Profile、§LoginLog、§OnlineUsers
- `spec/01-constraints.md` — §TypeScript 约束
- `spec/08-output-rules.md`

---

## API 层契约

以下各 `.ts` 文件调用的 endpoint 及类型签名：

| 文件 | 方法 | Endpoint | 说明 |
|------|------|----------|------|
| `api/dept.ts` | getDepts() | GET /api/v1/depts | 平铺列表 |
| `api/dept.ts` | getDeptTree() | GET /api/v1/depts/tree | 树形结构 |
| `api/dept.ts` | getDept(id) | GET /api/v1/depts/{id} | 详情 |
| `api/dept.ts` | createDept(dto) | POST /api/v1/depts | 创建 |
| `api/dept.ts` | updateDept(id, dto) | PUT /api/v1/depts/{id} | 更新 |
| `api/dept.ts` | deleteDept(id) | DELETE /api/v1/depts/{id} | 删除 |
| `api/profile.ts` | getProfile() | GET /api/v1/profile | 当前用户信息 |
| `api/profile.ts` | updateProfile(dto) | PUT /api/v1/profile | 修改个人信息 |
| `api/profile.ts` | updatePassword(dto) | PUT /api/v1/profile/password | 修改密码 |
| `api/loginLog.ts` | getLoginLogs(params) | GET /api/v1/login-logs | 分页查询 |
| `api/onlineUser.ts` | getOnlineUsers() | GET /api/v1/online-users | 在线用户列表 |
| `api/onlineUser.ts` | kickoutUser(tokenId) | DELETE /api/v1/online-users/{tokenId} | 强制下线 |

> `dept.ts` 中的类型（DeptVO、DeptTreeVO、DeptCreateDTO、DeptUpdateDTO）若 `@ljwx/shared` 未导出则在文件内本地定义，禁止 `any`。

---

## 视图组件契约

### system/dept/index.vue — 部门树形管理

- `el-tree` 展示部门树（`node-key="id"`，`props="{ children: 'children', label: 'name' }"`）
- 右侧表单：新增 / 编辑部门（parentId 下拉选树形）
- 删除按钮带 `ElMessageBox.confirm` 确认弹窗
- 状态列使用 `el-tag`（正常=success，停用=danger）

### system/menu/index.vue — 菜单树形管理

- `el-table` 树形模式（`row-key="id"`，`tree-props`）展示菜单列表
- 新增 / 编辑使用 `el-dialog` 弹窗，含菜单类型切换（目录/菜单/按钮）
- 图标字段使用 `@element-plus/icons-vue` 选择器（下拉展示图标列表）
- 路由路径、组件路径仅在类型为目录/菜单时显示，按钮类型仅显示权限字段

### system/profile/index.vue — 个人中心

- 左侧：头像展示 + 基本信息只读卡片
- 右侧 `el-tabs`：
  - Tab 1"基本信息"：昵称、邮箱、手机修改表单（PUT /api/v1/profile）
  - Tab 2"修改密码"：旧密码、新密码、确认密码三字段（PUT /api/v1/profile/password）
- 密码输入框使用 `type="password"` + show/hide toggle

### monitor/loginLog/index.vue — 登录日志

- 搜索栏：用户名（文本）、状态（select：全部/成功/失败）、登录时间范围（date-picker）
- `el-table` 展示：用户名、IP 地址、User-Agent、状态、登录时间
- 状态列：成功 → `el-tag type="success"`，失败 → `el-tag type="danger"`
- `el-pagination` 分页（pageSize 默认 20）

### monitor/onlineUser/index.vue — 在线用户

- `el-table` 展示：用户名、IP 地址、登录时间、Token ID（jti）
- 每行"强制下线"按钮，点击后 `ElMessageBox.confirm` 确认，调用 `kickoutUser(tokenId)`
- 下线成功后刷新列表

---

> 本 Phase 为纯前端，验证方式：`pnpm run type-check` 通过，无 TypeScript `any`

---

## 关键约束

- 禁止 TypeScript `any`，tsconfig 开启 `strict: true`
- 所有 API 调用类型优先复用 `@ljwx/shared`，缺失类型在对应 `.ts` 文件中本地定义
- 路由注册到已有 `router/index.ts`（scope 外文件，通过最小化 PATCH 追加路由条目）
- 前端依赖版本仅用 `~`（tilde），禁止 `^`（caret）
- `dept.ts` 与 Phase 21 已生成的同名文件冲突时，以本 Phase scope 为准覆盖

---

## 验收条件

- **AC-01**：`pnpm run type-check` 通过，零 TypeScript 错误
- **AC-02**：代码库中无 `any` 关键字出现于 scope 内文件
- **AC-03**：所有列表页（loginLog、onlineUser、dept）具备搜索栏 + 表格 + 分页
- **AC-04**：profile 页具备基本信息修改表单和密码修改表单两个 Tab
- **AC-05**：menu 页支持树形展示，新增/编辑弹窗含菜单类型切换逻辑
