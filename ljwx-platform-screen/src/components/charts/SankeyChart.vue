<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { echarts } from '@/utils/echarts-setup'
import type { EChartsOption } from 'echarts'

interface SankeyNode {
  name: string
}

interface SankeyLink {
  source: string
  target: string
  value: number
}

interface SankeyChartProps {
  title?: string
  nodes: SankeyNode[]
  links: SankeyLink[]
  height?: string
}

const props = withDefaults(defineProps<SankeyChartProps>(), {
  title: '',
  height: '300px',
})

const chartRef = ref<HTMLDivElement | null>(null)
let chartInstance: ReturnType<typeof echarts.init> | null = null

function buildOption(): EChartsOption {
  return {
    title: props.title ? { text: props.title } : undefined,
    tooltip: { trigger: 'item', triggerOn: 'mousemove' },
    series: [
      {
        type: 'sankey' as const,
        data: props.nodes,
        links: props.links,
        emphasis: { focus: 'adjacency' },
        lineStyle: { color: 'gradient', curveness: 0.5 },
      },
    ],
  }
}

function resizeChart() {
  chartInstance?.resize()
}

watch(
  () => [props.nodes, props.links],
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
