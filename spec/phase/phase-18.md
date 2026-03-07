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
- **AC-04**：数据对接 `/api/v1/screen/*` 接口
- **AC-05**：`pnpm run build` 通过

---

## 关键约束

- 禁止：`any` 类型
- 必须：≥13 个图表组件 · typed props · DataV 边框装饰

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-18-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-18-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-18-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-18-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-18-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-18-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-18-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-18-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-18-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-18-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
