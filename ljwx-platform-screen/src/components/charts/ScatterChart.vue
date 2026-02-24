<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface ScatterSeries {
  name: string
  data: [number, number][]
  color?: string
}

interface ScatterChartProps {
  title?: string
  series: ScatterSeries[]
  xName?: string
  yName?: string
  height?: string
}

const props = withDefaults(defineProps<ScatterChartProps>(), {
  title: '',
  xName: '',
  yName: '',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title } : undefined,
    tooltip: { trigger: 'item' },
    legend: { data: props.series.map((s) => s.name) },
    xAxis: { name: props.xName, type: 'value', scale: true },
    yAxis: { name: props.yName, type: 'value', scale: true },
    series: props.series.map((s) => ({
      name: s.name,
      type: 'scatter' as const,
      data: s.data,
      itemStyle: s.color ? { color: s.color } : undefined,
    })),
  }
}

function resizeChart() {
  chartInstance?.resize()
}

watch(
  () => props.series,
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
