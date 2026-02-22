# 前端配置

> 版本号见 CLAUDE.md "版本锁定"段。本文件中的 package.json 版本号均写 "见 CLAUDE.md"，实际生成时从 CLAUDE.md 取值。

## pnpm-workspace.yaml

```yaml
packages:
  - 'packages/*'
  - 'ljwx-platform-admin'
  - 'ljwx-platform-mobile'
  - 'ljwx-platform-screen'
```

## Root package.json

```json
{
  "name": "ljwx-platform-frontend",
  "private": true,
  "packageManager": "pnpm@10.30.1",
  "engines": {
    "node": ">=20.19.0 || >=22.12.0"
  },
  "scripts": {
    "dev:admin": "pnpm --filter ljwx-platform-admin dev",
    "dev:mobile": "pnpm --filter ljwx-platform-mobile dev:h5",
    "dev:screen": "pnpm --filter ljwx-platform-screen dev",
    "build:shared": "pnpm --filter @ljwx/shared build",
    "build:admin": "pnpm run build:shared && pnpm --filter ljwx-platform-admin build",
    "build:mobile": "pnpm run build:shared && pnpm --filter ljwx-platform-mobile build:h5",
    "build:screen": "pnpm run build:shared && pnpm --filter ljwx-platform-screen build",
    "build:all": "pnpm run build:shared && pnpm --filter './ljwx-platform-*' build",
    "type-check": "pnpm --filter './ljwx-platform-*' type-check",
    "lint": "pnpm --filter './ljwx-platform-*' lint"
  }
}
```

## .npmrc

```
shamefully-hoist=true
strict-peer-dependencies=false
auto-install-peers=true
```

## .nvmrc

```
22.22.0
```

## .env.example

```bash
# ===== Backend =====
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ljwx_platform
DB_USERNAME=postgres
DB_PASSWORD=postgres
JWT_SECRET=your-256-bit-secret-key-here-change-in-production
FILE_BASE_PATH=./uploads

# ===== Frontend =====
VITE_APP_BASE_API=/api
VITE_APP_TITLE=LJWX Platform
```

**注意：** 前端统一使用 `VITE_APP_BASE_API`。Admin / Mobile / Screen 的 `.env.development` 和 `.env.production` 均使用此变量名。

## Admin package.json

```json
{
  "name": "ljwx-platform-admin",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc --noEmit && vite build",
    "type-check": "vue-tsc --noEmit",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "~3.5.28",
    "vue-router": "~5.0.2",
    "pinia": "~3.0.4",
    "element-plus": "~2.13.2",
    "@element-plus/icons-vue": "~2.3.2",
    "axios": "~1.13.5",
    "@vueuse/core": "~14.2.1",
    "nprogress": "~0.2.0",
    "dayjs": "~1.11.19",
    "@ljwx/shared": "workspace:*"
  },
  "devDependencies": {
    "vite": "~7.3.1",
    "typescript": "~5.9.3",
    "vue-tsc": "~3.2.4",
    "@vitejs/plugin-vue": "~6.0.0",
    "unplugin-auto-import": "~21.0.0",
    "unplugin-vue-components": "~31.0.0",
    "sass": "~1.97.3",
    "@types/nprogress": "~0.2.3"
  }
}
```

## Admin vite.config.ts

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: ['vue', 'vue-router', 'pinia'],
      resolvers: [ElementPlusResolver()],
      dts: 'src/auto-imports.d.ts',
    }),
    Components({
      resolvers: [ElementPlusResolver()],
      dts: 'src/components.d.ts',
    }),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
```

## Admin Axios 封装要点

```typescript
// src/api/request.ts
import axios from 'axios'
import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'
import router from '@/router'

const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API,
  timeout: 15000,
})

// 请求拦截：注入 Authorization
service.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const userStore = useUserStore()
  if (userStore.accessToken) {
    config.headers.Authorization = `Bearer ${userStore.accessToken}`
  }
  return config
})

// 响应拦截：处理 401 刷新逻辑
let isRefreshing = false
let failedQueue: Array<{
  resolve: (value?: unknown) => void
  reject: (reason?: unknown) => void
}> = []

service.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message, data } = response.data
    if (code !== 200) {
      ElMessage.error(message || '请求失败')
      return Promise.reject(new Error(message))
    }
    return data
  },
  async (error) => {
    const originalRequest = error.config
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject })
        }).then(() => service(originalRequest))
      }
      originalRequest._retry = true
      isRefreshing = true
      try {
        const userStore = useUserStore()
        await userStore.refreshToken()
        failedQueue.forEach(({ resolve }) => resolve(undefined))
        failedQueue = []
        return service(originalRequest)
      } catch {
        failedQueue.forEach(({ reject }) => reject(error))
        failedQueue = []
        const userStore = useUserStore()
        userStore.logout()
        router.push('/login')
        return Promise.reject(error)
      } finally {
        isRefreshing = false
      }
    }
    ElMessage.error(error.response?.data?.message || '网络错误')
    return Promise.reject(error)
  },
)

export default service
```

## Mobile package.json

```json
{
  "name": "ljwx-platform-mobile",
  "version": "1.0.0",
  "scripts": {
    "dev:h5": "uni -p h5",
    "build:h5": "uni build -p h5"
  },
  "dependencies": {
    "@dcloudio/uni-app": "~3.0.0-alpha-4060620250520001",
    "@dcloudio/uni-h5": "~3.0.0-alpha-4060620250520001",
    "@dcloudio/uni-components": "~3.0.0-alpha-4060620250520001",
    "vue": "~3.5.28",
    "pinia": "~3.0.4",
    "axios": "~1.13.5",
    "@ljwx/shared": "workspace:*"
  },
  "devDependencies": {
    "@dcloudio/vite-plugin-uni": "~3.0.0-alpha-4060620250520001",
    "typescript": "~5.9.3",
    "vite": "~7.3.1"
  }
}
```

## Mobile pages.json

```json
{
  "pages": [
    { "path": "pages/login/index", "style": { "navigationBarTitleText": "登录" } },
    { "path": "pages/home/index", "style": { "navigationBarTitleText": "首页" } },
    { "path": "pages/work/index", "style": { "navigationBarTitleText": "工作台" } },
    { "path": "pages/message/index", "style": { "navigationBarTitleText": "消息" } },
    { "path": "pages/mine/index", "style": { "navigationBarTitleText": "我的" } }
  ],
  "tabBar": {
    "list": [
      { "pagePath": "pages/home/index", "text": "首页" },
      { "pagePath": "pages/work/index", "text": "工作台" },
      { "pagePath": "pages/message/index", "text": "消息" },
      { "pagePath": "pages/mine/index", "text": "我的" }
    ]
  },
  "globalStyle": {
    "navigationBarTextStyle": "black",
    "navigationBarTitleText": "LJWX",
    "navigationBarBackgroundColor": "#ffffff"
  }
}
```

## Screen package.json

```json
{
  "name": "ljwx-platform-screen",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc --noEmit && vite build",
    "type-check": "vue-tsc --noEmit",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "~3.5.28",
    "echarts": "~6.0.0",
    "@kjgl77/datav-vue3": "~1.7.4",
    "axios": "~1.13.5",
    "@vueuse/core": "~14.2.1",
    "@ljwx/shared": "workspace:*"
  },
  "devDependencies": {
    "vite": "~7.3.1",
    "typescript": "~5.9.3",
    "vue-tsc": "~3.2.4",
    "@vitejs/plugin-vue": "~6.0.0",
    "sass": "~1.97.3"
  }
}
```

## Screen ECharts 暗色主题注册

```typescript
// src/utils/echarts-setup.ts
import * as echarts from 'echarts'
import darkTheme from './echarts-dark-theme'

echarts.registerTheme('ljwx-dark', darkTheme)

export { echarts }
```

## Screen 自适应缩放 Composable

```typescript
// src/composables/useScreenAdapt.ts
import { ref, onMounted, onUnmounted } from 'vue'

export function useScreenAdapt(designWidth = 1920, designHeight = 1080) {
  const scale = ref(1)

  function updateScale() {
    const scaleX = window.innerWidth / designWidth
    const scaleY = window.innerHeight / designHeight
    scale.value = Math.min(scaleX, scaleY)
  }

  onMounted(() => {
    updateScale()
    window.addEventListener('resize', updateScale)
  })

  onUnmounted(() => {
    window.removeEventListener('resize', updateScale)
  })

  return { scale }
}
```
