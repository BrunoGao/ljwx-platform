<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'

interface WaterBallChartProps {
  title?: string
  value: number
  max?: number
  color?: string
  height?: string
}

const props = withDefaults(defineProps<WaterBallChartProps>(), {
  title: '',
  max: 100,
  color: '#00d4ff',
  height: '200px',
})

const percentage = computed(() => {
  const pct = Math.min(Math.max(props.value / props.max, 0), 1)
  return Math.round(pct * 100)
})

const waveStyle = computed(() => ({
  height: `${percentage.value}%`,
  background: `linear-gradient(180deg, ${props.color}88 0%, ${props.color} 100%)`,
}))
</script>

<template>
  <div class="water-ball-wrap" :style="{ height: props.height }">
    <div class="water-ball-title" v-if="props.title">{{ props.title }}</div>
    <div class="water-ball-container">
      <div class="water-ball-wave" :style="waveStyle" />
      <div class="water-ball-text">{{ percentage }}%</div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.water-ball-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.water-ball-title {
  font-size: 13px;
  color: #7a8ab8;
}

.water-ball-container {
  position: relative;
  width: 120px;
  height: 120px;
  border-radius: 50%;
  border: 2px solid #00d4ff44;
  overflow: hidden;
  background: #0a0e1a;
}

.water-ball-wave {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  transition: height 0.8s ease;
  border-radius: 0 0 50% 50%;
}

.water-ball-text {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  font-weight: 700;
  color: #fff;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.6);
}
</style>
