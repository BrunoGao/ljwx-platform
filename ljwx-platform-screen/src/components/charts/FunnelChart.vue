<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface FunnelItem {
  name: string
  value: number
}

interface FunnelChartProps {
  title?: string
  data: FunnelItem[]
  height?: string
}

const props = withDefaults(defineProps<FunnelChartProps>(), {
  title: '',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title, left: 'center' } : undefined,
    tooltip: { trigger: 'item', formatter: '{a} <br/>{b}: {c}%' },
    legend: { data: props.data.map((d) => d.name) },
    series: [
      {
        name: props.title,
        type: 'funnel' as const,
        left: '10%',
        width: '80%',
        label: { formatter: '{b}' },
        labelLine: { show: false },
        itemStyle: { opacity: 0.7 },
        emphasis: { label: { fontSize: 20 } },
        data: props.data,
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
