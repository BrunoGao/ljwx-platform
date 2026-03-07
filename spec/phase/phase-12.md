---
phase: 12
title: "Admin Scaffold (管理后台骨架)"
targets:
  backend: false
  frontend: true
depends_on: [11]
bundle_with: []
scope:
  - "ljwx-platform-admin/**"
---
# Phase 12 — 管理后台骨架 (Admin Scaffold)

| 项目 | 值 |
|-----|---|
| Phase | 12 |
| 模块 | ljwx-platform-admin (Vue 3 管理后台) |
| Feature | F-012 (Admin 基础架构) |
| 前置依赖 | Phase 11 (Shared Package) |
| 测试契约 | `spec/tests/phase-12-admin.tests.yml` |

## 读取清单

> 仅读取以下文件（禁止扫描整个 spec/）

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Admin package.json、§Admin vite.config.ts、§Admin Axios 封装
- `spec/01-constraints.md` — §JWT 认证（Refresh 流程）、§Vue Router 5 兼容性约束、§TypeScript 约束
- `spec/08-output-rules.md`

---

## 架构契约

### 技术栈

- Vue ~3.5.28
- Vite ~7.3.1
- TypeScript ~5.9.3
- Vue Router ~5.0.2（必须使用 v5 API）
- Pinia ~3.0.4
- Element Plus ~2.13.2
- Axios ~1.13.5

### 目录结构

```
ljwx-platform-admin/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
├── env.d.ts
├── .env.development
├── .env.production
├── index.html
├── src/
│   ├── main.ts
│   ├── App.vue
│   ├── router/
│   │   └── index.ts          # Vue Router 5 API
│   ├── stores/
│   │   ├── user.ts           # 用户状态（token 管理）
│   │   └── app.ts            # 应用状态（侧边栏、主题）
│   ├── api/
│   │   ├── request.ts        # Axios 封装（401 刷新队列）
│   │   └── auth.ts           # 登录/登出/刷新 API
│   ├── layouts/
│   │   ├── DefaultLayout.vue # 主布局（侧边栏 + 顶栏）
│   │   └── components/
│   │       ├── Sidebar.vue
│   │       └── Navbar.vue
│   ├── views/
│   │   ├── login/
│   │   │   └── index.vue     # 登录页
│   │   └── dashboard/
│   │       └── index.vue     # 首页
│   └── styles/
│       ├── index.scss
│       └── variables.scss
```

---

## 配置契约

### .env.development / .env.production

```bash
# 必须使用 VITE_APP_BASE_API（禁止 VITE_API_BASE_URL）
VITE_APP_BASE_API=http://localhost:8080
```

### vite.config.ts 关键配置

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      resolvers: [ElementPlusResolver()],
      imports: ['vue', 'vue-router', 'pinia'],
    }),
    Components({
      resolvers: [ElementPlusResolver()],
    }),
  ],
  resolve: {
    alias: {
      '@': '/src',
    },
  },
})
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    // ... 其他配置
  }
}
```

---

## Router 契约（Vue Router 5 API）

### router/index.ts

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: { requiresAuth: false },
  },
  {
    path: '/',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/dashboard',
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue'),
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// 路由守卫（使用 Composition API）
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()
  if (to.meta.requiresAuth && !userStore.accessToken) {
    next('/login')
  } else {
    next()
  }
})

export default router
```

**关键约束**：
- 必须使用 `createRouter` / `createWebHistory`（Vue Router 5 API）
- 禁止使用 Options API 路由守卫（如 `beforeRouteEnter`）
- 使用 `onBeforeRouteLeave` / `onBeforeRouteUpdate`（Composition API）

---

## Store 契约（Pinia）

### stores/user.ts

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { login, logout, refreshToken } from '@/api/auth'
import type { LoginDTO } from '@ljwx/shared'

export const useUserStore = defineStore('user', () => {
  const accessToken = ref<string>('')
  const refreshToken = ref<string>('')
  const userInfo = ref<UserVO | null>(null)

  // 登录
  async function loginAction(loginDTO: LoginDTO) {
    const res = await login(loginDTO)
    accessToken.value = res.accessToken
    refreshToken.value = res.refreshToken
    // 存储到 localStorage
    localStorage.setItem('accessToken', res.accessToken)
    localStorage.setItem('refreshToken', res.refreshToken)
  }

  // 登出
  async function logoutAction() {
    await logout()
    accessToken.value = ''
    refreshToken.value = ''
    userInfo.value = null
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
  }

  // 刷新 Token
  async function refreshTokenAction() {
    const res = await refreshToken(refreshToken.value)
    accessToken.value = res.accessToken
    localStorage.setItem('accessToken', res.accessToken)
  }

  return {
    accessToken,
    refreshToken,
    userInfo,
    loginAction,
    logoutAction,
    refreshTokenAction,
  }
})
```

---

## Axios 封装契约

### api/request.ts

```typescript
import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig } from 'axios'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'

const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API,
  timeout: 10000,
})

// 请求拦截器
service.interceptors.request.use(
  (config) => {
    const userStore = useUserStore()
    if (userStore.accessToken) {
      config.headers.Authorization = `Bearer ${userStore.accessToken}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器（401 刷新队列）
let isRefreshing = false
let requestQueue: Array<() => void> = []

service.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    const { response } = error
    if (response?.status === 401) {
      const userStore = useUserStore()
      if (!isRefreshing) {
        isRefreshing = true
        try {
          await userStore.refreshTokenAction()
          // 重试队列中的请求
          requestQueue.forEach((cb) => cb())
          requestQueue = []
          return service(error.config)
        } catch (refreshError) {
          // 刷新失败，跳转登录
          userStore.logoutAction()
          window.location.href = '/login'
          return Promise.reject(refreshError)
        } finally {
          isRefreshing = false
        }
      } else {
        // 等待刷新完成
        return new Promise((resolve) => {
          requestQueue.push(() => {
            resolve(service(error.config))
          })
        })
      }
    }
    ElMessage.error(response?.data?.message || '请求失败')
    return Promise.reject(error)
  }
)

export default service
```

---

## 业务规则

- **BL-12-01**：所有依赖版本使用 `~` 前缀，禁止 `^`
- **BL-12-02**：环境变量必须使用 `VITE_APP_BASE_API`，禁止 `VITE_API_BASE_URL`
- **BL-12-03**：Router 必须使用 Vue Router 5 API（`createRouter` / `createWebHistory`）
- **BL-12-04**：401 响应触发 Token 刷新，刷新失败跳转登录页
- **BL-12-05**：所有类型定义禁止 `any`，tsconfig 开启 `strict: true`

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-12-admin.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-12-01 | package.json 依赖全部用 ~ | P0 |
| TC-12-02 | .env 使用 VITE_APP_BASE_API | P0 |
| TC-12-03 | Router 使用 Vue Router 5 API | P0 |
| TC-12-04 | User Store 包含 token 管理方法 | P0 |
| TC-12-05 | Axios 封装含 401 刷新队列 | P0 |
| TC-12-06 | 构建成功 | P0 |

---

## 验收条件

- **AC-01**：package.json 所有依赖版本用 `~`，无 `^`
- **AC-02**：.env 文件使用 `VITE_APP_BASE_API`（禁止 `VITE_API_BASE_URL`）
- **AC-03**：router/index.ts 使用 Vue Router 5 API（`createRouter` / `createWebHistory`）
- **AC-04**：stores/user.ts 包含 `accessToken` / `refreshToken` / `loginAction` / `logoutAction` / `refreshTokenAction`
- **AC-05**：api/request.ts 包含 401 刷新队列逻辑
- **AC-06**：`pnpm run build` 成功（需先执行 `pnpm run build:shared`）

---

## 关键约束

- 禁止：`^` 版本前缀 · `VITE_API_BASE_URL` · Vue Router v4 API · `any` 类型
- 必须：`~` 版本前缀 · `VITE_APP_BASE_API` · Vue Router v5 API · `strict: true`
- Router：使用 Composition API 守卫（`onBeforeRouteLeave` / `onBeforeRouteUpdate`）
- Axios：401 响应触发 Token 刷新，刷新失败跳转登录

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-12-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-12-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-12-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-12-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-12-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-12-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-12-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-12-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-12-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-12-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
