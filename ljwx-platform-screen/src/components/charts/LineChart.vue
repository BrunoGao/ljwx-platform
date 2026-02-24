<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface LineChartProps {
  title?: string
  xData: string[]
  series: Array<{
    name: string
    data: number[]
    smooth?: boolean
    color?: string
  }>
  height?: string
}

const props = withDefaults(defineProps<LineChartProps>(), {
  title: '',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title } : undefined,
    tooltip: { trigger: 'axis' },
    legend: { data: props.series.map((s) => s.name) },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: props.xData, boundaryGap: false },
    yAxis: { type: 'value' },
    series: props.series.map((s) => ({
      name: s.name,
      type: 'line' as const,
      data: s.data,
      smooth: s.smooth ?? true,
      itemStyle: s.color ? { color: s.color } : undefined,
    })),
  }
}

function resizeChart() {
  chartInstance?.resize()
}

watch(
  () => [props.xData, props.series],
  () => {
    chartInstance?.setOption(buildOption())
  },
  { deep: true },
)

onMounted(() => {
  if (!chartRef.value) return
  chartInstance = echarts.init(chartRef.value, 'ljwx-dark')
  chartInstance.setOption(buildOption())
  window.addEventListener('resize', resizeChart)
})

onUnmounted(() => {
  window.removeEventListener('resize', resizeChart)
  chartInstance?.dispose()
})
</script>

<template>
  <div ref="chartRef" :style="{ width: '100%', height: props.height }" />
</template>

<style scoped lang="scss">
</style>
