---
phase: 15
title: "Mobile Scaffold"
targets:
  backend: false
  frontend: true
depends_on: [11]
bundle_with: [16]
scope:
  - "ljwx-platform-mobile/**"
---
# Phase 15: Mobile Scaffold

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Mobile package.json、§Mobile pages.json
- `spec/01-constraints.md` — §TypeScript 约束、§JWT 认证
- `spec/08-output-rules.md`

## 任务

uni-app 骨架：登录、首页、tabBar 配置。

## Phase-Local Manifest

```
ljwx-platform-mobile/package.json
ljwx-platform-mobile/manifest.json
ljwx-platform-mobile/pages.json
ljwx-platform-mobile/tsconfig.json
ljwx-platform-mobile/.env.development
ljwx-platform-mobile/.env.production
ljwx-platform-mobile/src/main.ts
ljwx-platform-mobile/src/App.vue
ljwx-platform-mobile/src/pages/login/index.vue
ljwx-platform-mobile/src/pages/home/index.vue
ljwx-platform-mobile/src/stores/user.ts
ljwx-platform-mobile/src/api/request.ts
ljwx-platform-mobile/src/api/auth.ts
```

## 验收条件

1. package.json 依赖全部用 `~`，无 `^`
2. .env 使用 `VITE_APP_BASE_API`
3. 登录页面可正常显示
4. tabBar 包含 4 个页面
5. 无 `any`

## 可 Bundle

可与 Phase 16 一起执行。
