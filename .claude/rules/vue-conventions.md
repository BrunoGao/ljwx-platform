---
paths:
  - "ljwx-platform-admin/**/*.vue"
  - "ljwx-platform-admin/**/*.ts"
  - "ljwx-platform-admin/**/*.tsx"
  - "ljwx-platform-screen/**/*.vue"
  - "ljwx-platform-mobile/**/*.vue"
---

# Vue 3 / TypeScript 规范 — LJWX Platform

## TypeScript 硬规则

- **禁止** `: any`、`as any`、`<any>`
- `tsconfig.json` 必须 `"strict": true`
- 所有 props、emits、ref 必须有明确类型

## 组件写法

正确：
```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import type { UserVO } from '@ljwx/shared'
const users = ref<UserVO[]>([])
</script>
<style scoped lang="scss">
// scoped styles
</style>
```

- 只用 `<script setup lang="ts">` 语法糖
- **禁止** Options API、`defineComponent()`
- 样式必须 `<style scoped lang="scss">`

## Vue Router v5 API（重要）

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
// Composition API:
const route = useRoute()
const router = useRouter()
// 路由守卫（v5 合法写法）:
onBeforeRouteLeave((to, from) => { ... })
onBeforeRouteUpdate((to, from) => { ... })
```

- **禁止** Options API 路由守卫（`beforeRouteLeave` / `beforeRouteUpdate` 写在组件选项里）
- **禁止** v4 专属的 `useLink`（v5 已内置）
- 所有路由视图必须懒加载：`component: () => import('...')`
- 路由文件：手动定义，不使用文件系统路由

## API 调用

```typescript
import request from '@/api/request'
// 返回类型从 @ljwx/shared 引入
```

- API 调用只通过 `src/api/*.ts` 模块，**禁止**在组件内直接 fetch / axios
- **禁止** `VITE_API_BASE_URL`、`VITE_BASE_API` 等变量，只用 `VITE_APP_BASE_API`

## Pinia Store

```typescript
export const useUserStore = defineStore('user', () => {
  const token = ref<string>('')
  return { token }
})
```

- 使用 setup function 语法，禁止 options 语法
- Store 文件放 `src/stores/`

## package.json 依赖版本

- 所有 `dependencies` / `devDependencies` 只用 `~`（tilde patch）
- **禁止** `^`（caret）
- 版本号以 CLAUDE.md "版本锁定" 表为唯一来源
