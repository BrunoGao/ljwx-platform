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

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-14-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-14-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-14-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-14-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-14-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-14-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-14-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-14-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-14-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-14-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
