<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'

interface NumberFlipProps {
  value: number
  label?: string
  unit?: string
  duration?: number
  color?: string
}

const props = withDefaults(defineProps<NumberFlipProps>(), {
  label: '',
  unit: '',
  duration: 1500,
  color: '#00d4ff',
})

const displayValue = ref(0)

function animateTo(target: number) {
  const start = displayValue.value
  const diff = target - start
  const startTime = performance.now()

  function step(now: number) {
    const elapsed = now - startTime
    const progress = Math.min(elapsed / props.duration, 1)
    // ease-out cubic
    const eased = 1 - Math.pow(1 - progress, 3)
    displayValue.value = Math.round(start + diff * eased)
    if (progress < 1) {
      requestAnimationFrame(step)
    }
  }

  requestAnimationFrame(step)
}

watch(
  () => props.value,
  (newVal) => {
    animateTo(newVal)
  },
)

onMounted(() => {
  animateTo(props.value)
})
</script>

<template>
  <div class="number-flip">
    <div class="number-flip__label" v-if="props.label">{{ props.label }}</div>
    <div class="number-flip__value" :style="{ color: props.color }">
      {{ displayValue.toLocaleString() }}
      <span class="number-flip__unit" v-if="props.unit">{{ props.unit }}</span>
    </div>
  </div>
</template>

<style scoped lang="scss">
.number-flip {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;

  &__label {
    font-size: 13px;
    color: #7a8ab8;
  }

  &__value {
    font-size: 36px;
    font-weight: 700;
    font-variant-numeric: tabular-nums;
    letter-spacing: 2px;
    text-shadow: 0 0 16px currentColor;
    transition: color 0.3s;
  }

  &__unit {
    font-size: 16px;
    font-weight: 400;
    margin-left: 4px;
    opacity: 0.8;
  }
}
</style>
