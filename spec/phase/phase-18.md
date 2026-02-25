---
phase: 18
title: "Screen Components (数据大屏组件)"
targets:
  backend: false
  frontend: true
depends_on: [17]
bundle_with: [17]
scope:
  - "ljwx-platform-screen/src/components/**"
  - "ljwx-platform-screen/src/views/home/index.vue"
---
# Phase 18 — 数据大屏组件 (Screen Components)

| 项目 | 值 |
|-----|---|
| Phase | 18 |
| 模块 | ljwx-platform-screen (Vue 3 数据大屏) |
| Feature | F-018 (Screen 图表组件) |
| 前置依赖 | Phase 17 (Screen Scaffold) |
| 测试契约 | `spec/tests/phase-18-screen-components.tests.yml` |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/03-api.md` — §Screen 路由
- `spec/08-output-rules.md`

---

## 功能契约

### 图表组件清单（≥13 个）

| 组件 | 文件 | 类型 |
|------|------|------|
| 柱状图 | components/charts/BarChart.vue | ECharts |
| 折线图 | components/charts/LineChart.vue | ECharts |
| 饼图 | components/charts/PieChart.vue | ECharts |
| 雷达图 | components/charts/RadarChart.vue | ECharts |
| 仪表盘 | components/charts/GaugeChart.vue | ECharts |
| 散点图 | components/charts/ScatterChart.vue | ECharts |
| 地图 | components/charts/MapChart.vue | ECharts |
| 漏斗图 | components/charts/FunnelChart.vue | ECharts |
| 热力图 | components/charts/HeatmapChart.vue | ECharts |
| 矩形树图 | components/charts/TreemapChart.vue | ECharts |
| 桑基图 | components/charts/SankeyChart.vue | ECharts |
| 水球图 | components/charts/WaterBallChart.vue | ECharts |
| 环形图 | components/charts/RingChart.vue | ECharts |

### 组件结构

```vue
<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import echarts from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface Props {
  data: any[]
  title?: string
}

const props = defineProps<Props>()
const chartRef = ref<HTMLDivElement>()
let chartInstance: echarts.ECharts | null = null

function initChart() {
  if (!chartRef.value) return
  chartInstance = echarts.init(chartRef.value, 'dark')
  updateChart()
}

function updateChart() {
  const option: EChartsOption = {
    // 图表配置
  }
  chartInstance?.setOption(option)
}

watch(() => props.data, updateChart, { deep: true })

onMounted(initChart)
</script>

<template>
  <div ref="chartRef" class="chart-container"></div>
</template>
```

---

## 验收条件

- **AC-01**：≥ 13 个图表组件
- **AC-02**：每个组件接收 typed props，无 `any`
- **AC-03**：大屏首页布局完整，使用 DataV 边框装饰
- **AC-04**：数据对接 `/api/screen/*` 接口
- **AC-05**：`pnpm run build` 通过

---

## 关键约束

- 禁止：`any` 类型
- 必须：≥13 个图表组件 · typed props · DataV 边框装饰
