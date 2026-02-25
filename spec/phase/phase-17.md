---
phase: 17
title: "Screen Scaffold (数据大屏骨架)"
targets:
  backend: false
  frontend: true
depends_on: [11]
bundle_with: [18]
scope:
  - "ljwx-platform-screen/**"
---
# Phase 17 — 数据大屏骨架 (Screen Scaffold)

| 项目 | 值 |
|-----|---|
| Phase | 17 |
| 模块 | ljwx-platform-screen (Vue 3 数据大屏) |
| Feature | F-017 (Screen 基础架构) |
| 前置依赖 | Phase 11 (Shared Package) |
| 测试契约 | `spec/tests/phase-17-screen.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/06-frontend-config.md` — §Screen package.json、§Screen ECharts 暗色主题、§Screen 自适应缩放
- `spec/01-constraints.md` — §TypeScript 约束
- `spec/08-output-rules.md`

---

## 架构契约

### 技术栈

- Vue ~3.5.28
- Vite ~7.3.1
- TypeScript ~5.9.3
- ECharts ~6.0.0
- @kjgl77/datav-vue3 ~1.7.4

### 目录结构

```
ljwx-platform-screen/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── .env.development
├── .env.production
├── index.html
├── src/
│   ├── main.ts
│   ├── App.vue
│   ├── router/index.ts
│   ├── composables/
│   │   └── useScreenAdapt.ts
│   ├── utils/
│   │   ├── echarts-setup.ts
│   │   └── echarts-dark-theme.ts
│   ├── layouts/
│   │   └── ScreenLayout.vue
│   ├── views/
│   │   └── home/index.vue
│   ├── api/
│   │   ├── request.ts
│   │   └── screen.ts
│   └── styles/
│       └── index.scss
```

### ECharts 暗色主题注册

**utils/echarts-setup.ts**

```typescript
import * as echarts from 'echarts'
import darkTheme from './echarts-dark-theme'

echarts.registerTheme('dark', darkTheme)

export default echarts
```

### 自适应缩放

**composables/useScreenAdapt.ts**

```typescript
import { ref, onMounted, onUnmounted } from 'vue'

export function useScreenAdapt(designWidth = 1920, designHeight = 1080) {
  const scale = ref(1)

  function calcScale() {
    const width = window.innerWidth
    const height = window.innerHeight
    const scaleX = width / designWidth
    const scaleY = height / designHeight
    scale.value = Math.min(scaleX, scaleY)
  }

  onMounted(() => {
    calcScale()
    window.addEventListener('resize', calcScale)
  })

  onUnmounted(() => {
    window.removeEventListener('resize', calcScale)
  })

  return { scale }
}
```

---

## 验收条件

- **AC-01**：package.json 依赖全部用 `~`，无 `^`
- **AC-02**：.env 使用 `VITE_APP_BASE_API`
- **AC-03**：暗色主题已注册
- **AC-04**：自适应缩放 composable 正确（设计宽度 1920×1080）
- **AC-05**：无 `any` 类型
- **AC-06**：`pnpm run build` 通过

---

## 关键约束

- 禁止：`^` 版本前缀 · `any` 类型
- 必须：`~` 版本前缀 · ECharts 暗色主题 · 自适应缩放
