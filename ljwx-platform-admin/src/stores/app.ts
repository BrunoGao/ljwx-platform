import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAppStore = defineStore('app', () => {
  const sidebarCollapsed = ref<boolean>(false)
  const device = ref<'desktop' | 'mobile'>('desktop')
  const appTitle = ref<string>(import.meta.env.VITE_APP_TITLE ?? 'LJWX Platform')

  const isMobile = computed(() => device.value === 'mobile')

  function toggleSidebar(): void {
    sidebarCollapsed.value = !sidebarCollapsed.value
  }

  function setSidebarCollapsed(collapsed: boolean): void {
    sidebarCollapsed.value = collapsed
  }

  function setDevice(d: 'desktop' | 'mobile'): void {
    device.value = d
  }

  return {
    sidebarCollapsed,
    device,
    appTitle,
    isMobile,
    toggleSidebar,
    setSidebarCollapsed,
    setDevice,
  }
})
