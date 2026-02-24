<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface TreemapNode {
  name: string
  value: number
  children?: TreemapNode[]
}

interface TreemapChartProps {
  title?: string
  data: TreemapNode[]
  height?: string
}

const props = withDefaults(defineProps<TreemapChartProps>(), {
  title: '',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title, left: 'center' } : undefined,
    tooltip: { formatter: '{b}: {c}' },
    series: [
      {
        type: 'treemap' as const,
        data: props.data,
        label: { show: true, formatter: '{b}' },
        upperLabel: { show: true, height: 30 },
        itemStyle: { borderColor: '#0a0e1a', borderWidth: 2 },
        levels: [
          { itemStyle: { borderWidth: 0, gapWidth: 5 } },
          { itemStyle: { gapWidth: 1 } },
        ],
      },
    ],
  }
}

function resizeChart() {
  chartInstance?.resize()
}

watch(
  () => props.data,
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
