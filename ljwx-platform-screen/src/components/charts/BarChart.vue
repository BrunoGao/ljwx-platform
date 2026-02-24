<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface BarChartProps {
  title?: string
  xData: string[]
  series: Array<{
    name: string
    data: number[]
    color?: string
  }>
  height?: string
}

const props = withDefaults(defineProps<BarChartProps>(), {
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
    xAxis: { type: 'category', data: props.xData },
    yAxis: { type: 'value' },
    series: props.series.map((s) => ({
      name: s.name,
      type: 'bar' as const,
      data: s.data,
      itemStyle: s.color ? { color: s.color } : undefined,
    })),
  }
}

function initChart() {
  if (!chartRef.value) return
  chartInstance = echarts.init(chartRef.value, 'ljwx-dark')
  chartInstance.setOption(buildOption())
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
  initChart()
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
