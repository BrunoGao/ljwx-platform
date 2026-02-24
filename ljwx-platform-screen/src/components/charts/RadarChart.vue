<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface RadarIndicator {
  name: string
  max: number
}

interface RadarSeries {
  name: string
  value: number[]
}

interface RadarChartProps {
  title?: string
  indicators: RadarIndicator[]
  series: RadarSeries[]
  height?: string
}

const props = withDefaults(defineProps<RadarChartProps>(), {
  title: '',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title } : undefined,
    tooltip: {},
    legend: { data: props.series.map((s) => s.name) },
    radar: { indicator: props.indicators },
    series: [
      {
        type: 'radar' as const,
        data: props.series.map((s) => ({ name: s.name, value: s.value })),
      },
    ],
  }
}

function resizeChart() {
  chartInstance?.resize()
}

watch(
  () => [props.indicators, props.series],
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
