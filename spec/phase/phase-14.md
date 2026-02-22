---
phase: 14
title: "Admin Permission and Polish"
targets:
  backend: false
  frontend: true
depends_on: [13]
bundle_with: []
scope:
  - "ljwx-platform-admin/src/router/guards.ts"
  - "ljwx-platform-admin/src/stores/permission.ts"
  - "ljwx-platform-admin/src/composables/usePermission.ts"
  - "ljwx-platform-admin/src/composables/useTheme.ts"
  - "ljwx-platform-admin/src/layouts/components/Breadcrumb.vue"
  - "ljwx-platform-admin/src/layouts/components/TagsView.vue"
  - "ljwx-platform-admin/src/layouts/components/ThemeSwitch.vue"
---
# Phase 14: Admin Permission & Polish

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §RBAC 权限
- `spec/08-output-rules.md`

## 任务

动态路由权限过滤、面包屑、标签页、主题切换。

## Phase-Local Manifest

```
ljwx-platform-admin/src/router/guards.ts
ljwx-platform-admin/src/stores/permission.ts
ljwx-platform-admin/src/composables/usePermission.ts
ljwx-platform-admin/src/layouts/components/Breadcrumb.vue
ljwx-platform-admin/src/layouts/components/TagsView.vue
ljwx-platform-admin/src/layouts/components/ThemeSwitch.vue
ljwx-platform-admin/src/composables/useTheme.ts
```

## 验收条件

1. 路由守卫根据用户权限动态过滤菜单
2. 无权限的路由不可访问
3. 面包屑、标签页正常显示
4. 主题切换（亮色/暗色）功能正常
5. build 通过
