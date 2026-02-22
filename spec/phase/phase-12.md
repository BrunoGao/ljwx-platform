---
phase: 12
title: "Admin Scaffold"
targets:
  backend: false
  frontend: true
depends_on: [11]
bundle_with: []
scope:
  - "ljwx-platform-admin/**"
---
# Phase 12: Admin Scaffold

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Admin package.json、§Admin vite.config.ts、§Admin Axios 封装
- `spec/01-constraints.md` — §JWT 认证（Refresh 流程）、§Vue Router 5 兼容性约束、§TypeScript 约束
- `spec/08-output-rules.md`

## 任务

Vue 3 + Vite + Element Plus 骨架：router（vue-router @5 API）、stores（user store 含 token 管理）、layouts（侧边栏 + 顶栏）、login 页面。

## 关键约束

- **必须使用 vue-router @5 API**，禁止按 v4 写
- 无 `any`，`strict: true`
- Axios baseURL 使用 `import.meta.env.VITE_APP_BASE_API`
- 401 刷新逻辑参考 spec/06-frontend-config.md §Axios 封装

## Phase-Local Manifest

```
ljwx-platform-admin/package.json
ljwx-platform-admin/vite.config.ts
ljwx-platform-admin/tsconfig.json
ljwx-platform-admin/tsconfig.app.json
ljwx-platform-admin/tsconfig.node.json
ljwx-platform-admin/env.d.ts
ljwx-platform-admin/.env.development
ljwx-platform-admin/.env.production
ljwx-platform-admin/index.html
ljwx-platform-admin/src/main.ts
ljwx-platform-admin/src/App.vue
ljwx-platform-admin/src/router/index.ts
ljwx-platform-admin/src/stores/user.ts
ljwx-platform-admin/src/stores/app.ts
ljwx-platform-admin/src/api/request.ts
ljwx-platform-admin/src/api/auth.ts
ljwx-platform-admin/src/layouts/DefaultLayout.vue
ljwx-platform-admin/src/layouts/components/Sidebar.vue
ljwx-platform-admin/src/layouts/components/Navbar.vue
ljwx-platform-admin/src/views/login/index.vue
ljwx-platform-admin/src/views/dashboard/index.vue
ljwx-platform-admin/src/styles/index.scss
ljwx-platform-admin/src/styles/variables.scss
```

## 验收条件

1. package.json 所有依赖版本用 `~`，无 `^`
2. .env 文件使用 `VITE_APP_BASE_API`
3. router 使用 vue-router @5 API
4. user store 包含 accessToken / refreshToken / login / logout / refreshToken 方法
5. Axios 封装含 401 刷新队列逻辑
6. `pnpm run build:admin` 通过（先执行 build:shared）
