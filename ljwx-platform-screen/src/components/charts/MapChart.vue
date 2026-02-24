<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface MapDataItem {
  name: string
  value: number
}

interface MapChartProps {
  title?: string
  mapName?: string
  data: MapDataItem[]
  height?: string
}

const props = withDefaults(defineProps<MapChartProps>(), {
  title: '',
  mapName: 'china',
  height: '400px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title, left: 'center' } : undefined,
    tooltip: { trigger: 'item', formatter: '{b}: {c}' },
    visualMap: {
      min: 0,
      max: Math.max(...props.data.map((d) => d.value), 1),
      left: 'left',
      top: 'bottom',
      text: ['高', '低'],
      calculable: true,
      inRange: { color: ['#1e3a5f', '#00d4ff'] },
    },
    series: [
      {
        type: 'map' as const,
        map: props.mapName,
        data: props.data,
        emphasis: {
          label: { show: true },
          itemStyle: { areaColor: '#00d4ff' },
        },
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
