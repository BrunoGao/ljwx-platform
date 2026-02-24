<script setup lang="ts">
import { computed } from 'vue'
import { RouterView } from 'vue-router'
import { useScreenAdapt } from '@/composables/useScreenAdapt'

const { scale } = useScreenAdapt(1920, 1080)

const containerStyle = computed(() => ({
  transform: `scale(${scale.value})`,
  transformOrigin: 'top left',
  width: '1920px',
  height: '1080px',
}))
</script>

<template>
  <div class="screen-wrapper">
    <div class="screen-container" :style="containerStyle">
      <RouterView />
    </div>
  </div>
</template>

<style scoped lang="scss">
.screen-wrapper {
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  background-color: #0a0e1a;
  display: flex;
  align-items: flex-start;
  justify-content: flex-start;
}

.screen-container {
  position: relative;
  background-color: #0a0e1a;
}
</style>
