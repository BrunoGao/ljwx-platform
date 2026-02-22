---
phase: 16
title: "Mobile Feature Pages"
targets:
  backend: false
  frontend: true
depends_on: [15]
bundle_with: [15]
scope:
  - "ljwx-platform-mobile/src/pages/**"
  - "ljwx-platform-mobile/src/api/notice.ts"
  - "ljwx-platform-mobile/src/api/user.ts"
---
# Phase 16: Mobile Feature Pages

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Mobile pages.json
- `spec/08-output-rules.md`

## 任务

移动端工作台、消息、个人中心页面。

## Phase-Local Manifest

```
ljwx-platform-mobile/src/pages/work/index.vue
ljwx-platform-mobile/src/pages/message/index.vue
ljwx-platform-mobile/src/pages/mine/index.vue
ljwx-platform-mobile/src/api/notice.ts
ljwx-platform-mobile/src/api/user.ts
```

## 验收条件

1. 四个 tabBar 页面均有内容
2. 无 `any`
3. build:h5 通过（如 uni-app CLI 可用）

## 可 Bundle

可与 Phase 15 一起执行。
