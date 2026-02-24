<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface HeatmapChartProps {
  title?: string
  xData: string[]
  yData: string[]
  data: [number, number, number][]
  height?: string
}

const props = withDefaults(defineProps<HeatmapChartProps>(), {
  title: '',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  const values = props.data.map((d) => d[2])
  const minVal = values.length > 0 ? Math.min(...values) : 0
  const maxVal = values.length > 0 ? Math.max(...values) : 1
  return {
    title: props.title ? { text: props.title } : undefined,
    tooltip: { position: 'top' },
    grid: { height: '50%', top: '10%' },
    xAxis: { type: 'category', data: props.xData, splitArea: { show: true } },
    yAxis: { type: 'category', data: props.yData, splitArea: { show: true } },
    visualMap: {
      min: minVal,
      max: maxVal,
      calculable: true,
      orient: 'horizontal',
      left: 'center',
      bottom: '15%',
      inRange: { color: ['#1e3a5f', '#00d4ff'] },
    },
    series: [
      {
        type: 'heatmap' as const,
        data: props.data,
        label: { show: true },
        emphasis: { itemStyle: { shadowBlur: 10, shadowColor: 'rgba(0, 0, 0, 0.5)' } },
      },
    ],
  }
}

function resizeChart() {
  chartInstance?.resize()
}

watch(
  () => [props.xData, props.yData, props.data],
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
