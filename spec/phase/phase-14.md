---
phase: 14
title: "Admin Permission and Polish (管理后台权限与优化)"
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
# Phase 14 — 管理后台权限与优化 (Admin Permission & Polish)

| 项目 | 值 |
|-----|---|
| Phase | 14 |
| 模块 | ljwx-platform-admin (Vue 3 管理后台) |
| Feature | F-014 (动态路由权限、面包屑、标签页、主题切换) |
| 前置依赖 | Phase 13 (Admin CRUD Pages) |
| 测试契约 | `spec/tests/phase-14-permission.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/01-constraints.md` — §RBAC 权限
- `spec/08-output-rules.md`

---

## 功能契约

### 1. 动态路由权限过滤

**stores/permission.ts**

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from './user'

export const usePermissionStore = defineStore('permission', () => {
  const routes = ref<RouteRecordRaw[]>([])
  const addRoutes = ref<RouteRecordRaw[]>([])

  // 根据用户权限过滤路由
  function filterRoutes(routes: RouteRecordRaw[], permissions: string[]): RouteRecordRaw[] {
    const res: RouteRecordRaw[] = []
    routes.forEach(route => {
      const tmp = { ...route }
      if (hasPermission(permissions, tmp)) {
        if (tmp.children) {
          tmp.children = filterRoutes(tmp.children, permissions)
        }
        res.push(tmp)
      }
    })
    return res
  }

  // 检查权限
  function hasPermission(permissions: string[], route: RouteRecordRaw): boolean {
    if (route.meta?.permission) {
      return permissions.includes(route.meta.permission as string)
    }
    return true
  }

  // 生成路由
  async function generateRoutes() {
    const userStore = useUserStore()
    const permissions = userStore.permissions || []
    const accessedRoutes = filterRoutes(asyncRoutes, permissions)
    addRoutes.value = accessedRoutes
    routes.value = constantRoutes.concat(accessedRoutes)
    return accessedRoutes
  }

  return { routes, addRoutes, generateRoutes }
})
```

**router/guards.ts**

```typescript
import type { Router } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { usePermissionStore } from '@/stores/permission'

export function setupRouterGuards(router: Router) {
  router.beforeEach(async (to, from, next) => {
    const userStore = useUserStore()
    const permissionStore = usePermissionStore()

    if (userStore.accessToken) {
      if (to.path === '/login') {
        next('/')
      } else {
        if (!userStore.permissions || userStore.permissions.length === 0) {
          try {
            await userStore.getUserInfo()
            const accessRoutes = await permissionStore.generateRoutes()
            accessRoutes.forEach(route => {
              router.addRoute(route)
            })
            next({ ...to, replace: true })
          } catch (error) {
            await userStore.logoutAction()
            next('/login')
          }
        } else {
          next()
        }
      }
    } else {
      if (to.meta.requiresAuth === false) {
        next()
      } else {
        next('/login')
      }
    }
  })
}
```

### 2. 权限指令

**composables/usePermission.ts**

```typescript
import { useUserStore } from '@/stores/user'

export function usePermission() {
  const userStore = useUserStore()

  function hasPermission(permission: string | string[]): boolean {
    const permissions = userStore.permissions || []
    if (Array.isArray(permission)) {
      return permission.some(p => permissions.includes(p))
    }
    return permissions.includes(permission)
  }

  function hasAllPermissions(permissions: string[]): boolean {
    const userPermissions = userStore.permissions || []
    return permissions.every(p => userPermissions.includes(p))
  }

  return { hasPermission, hasAllPermissions }
}
```

### 3. 面包屑导航

**layouts/components/Breadcrumb.vue**

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const breadcrumbs = computed(() => {
  return route.matched.filter(item => item.meta?.title)
})
</script>

<template>
  <el-breadcrumb separator="/">
    <el-breadcrumb-item v-for="item in breadcrumbs" :key="item.path">
      {{ item.meta?.title }}
    </el-breadcrumb-item>
  </el-breadcrumb>
</template>
```

### 4. 标签页视图

**layouts/components/TagsView.vue**

```typescript
// 标签页管理：打开、关闭、刷新当前页
```

### 5. 主题切换

**composables/useTheme.ts**

```typescript
import { ref } from 'vue'

export function useTheme() {
  const isDark = ref(false)

  function toggleTheme() {
    isDark.value = !isDark.value
    document.documentElement.classList.toggle('dark', isDark.value)
  }

  return { isDark, toggleTheme }
}
```

---

## 验收条件

- **AC-01**：路由守卫根据用户权限动态过滤菜单
- **AC-02**：无权限的路由不可访问（403 或重定向）
- **AC-03**：面包屑、标签页正常显示
- **AC-04**：主题切换（亮色/暗色）功能正常
- **AC-05**：`pnpm run build` 通过

---

## 关键约束

- 权限过滤：基于用户权限字符串数组动态生成路由
- 路由守卫：使用 Vue Router 5 API（`router.beforeEach`）
- 禁止：`any` 类型 · 硬编码权限判断
