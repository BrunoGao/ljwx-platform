import { ref, onMounted, onUnmounted } from 'vue'

export function useScreenAdapt(designWidth = 1920, designHeight = 1080) {
  const scale = ref(1)

  function updateScale() {
    const scaleX = window.innerWidth / designWidth
    const scaleY = window.innerHeight / designHeight
    scale.value = Math.min(scaleX, scaleY)
  }

  onMounted(() => {
    updateScale()
    window.addEventListener('resize', updateScale)
  })

  onUnmounted(() => {
    window.removeEventListener('resize', updateScale)
  })

  return { scale }
}
