---
phase: 17
title: "Screen Scaffold"
targets:
  backend: false
  frontend: true
depends_on: [11]
bundle_with: [18]
scope:
  - "ljwx-platform-screen/**"
---
# Phase 17: Screen Scaffold

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Screen package.json、§Screen ECharts 暗色主题、§Screen 自适应缩放
- `spec/01-constraints.md` — §TypeScript 约束
- `spec/08-output-rules.md`

## 任务

Vue 3 + ECharts + DataV 骨架：暗色主题注册、自适应缩放 composable、基础布局。

## Phase-Local Manifest

```
ljwx-platform-screen/package.json
ljwx-platform-screen/vite.config.ts
ljwx-platform-screen/tsconfig.json
ljwx-platform-screen/.env.development
ljwx-platform-screen/.env.production
ljwx-platform-screen/index.html
ljwx-platform-screen/src/main.ts
ljwx-platform-screen/src/App.vue
ljwx-platform-screen/src/router/index.ts
ljwx-platform-screen/src/composables/useScreenAdapt.ts
ljwx-platform-screen/src/utils/echarts-setup.ts
ljwx-platform-screen/src/utils/echarts-dark-theme.ts
ljwx-platform-screen/src/layouts/ScreenLayout.vue
ljwx-platform-screen/src/views/home/index.vue
ljwx-platform-screen/src/api/request.ts
ljwx-platform-screen/src/api/screen.ts
ljwx-platform-screen/src/styles/index.scss
```

## 验收条件

1. package.json 依赖全部用 `~`，无 `^`
2. .env 使用 `VITE_APP_BASE_API`
3. 暗色主题已注册
4. 自适应缩放 composable 正确（设计宽度 1920×1080）
5. 无 `any`
6. build 通过

## 可 Bundle

可与 Phase 18 一起执行。
