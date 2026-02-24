<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface GaugeChartProps {
  title?: string
  value: number
  min?: number
  max?: number
  unit?: string
  height?: string
}

const props = withDefaults(defineProps<GaugeChartProps>(), {
  title: '',
  min: 0,
  max: 100,
  unit: '%',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title, left: 'center' } : undefined,
    series: [
      {
        type: 'gauge' as const,
        min: props.min,
        max: props.max,
        detail: { formatter: `{value}${props.unit}`, color: '#00d4ff' },
        data: [{ value: props.value, name: props.title }],
        axisLine: {
          lineStyle: {
            width: 10,
            color: [
              [0.3, '#00ff88'],
              [0.7, '#ffaa00'],
              [1, '#ff4466'],
            ],
          },
        },
      },
    ],
  }
}

function resizeChart() {
  chartInstance?.resize()
}

watch(
  () => props.value,
  () => {
    chartInstance?.setOption(buildOption())
  },
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
