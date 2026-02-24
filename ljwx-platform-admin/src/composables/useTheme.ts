import { ref, watchEffect } from 'vue'
import { usePreferredDark } from '@vueuse/core'

export type ThemeMode = 'light' | 'dark' | 'system'

const STORAGE_KEY = 'ljwx_theme'

function readStoredTheme(): ThemeMode {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored === 'light' || stored === 'dark' || stored === 'system') {
    return stored
  }
  return 'light'
}

/** Singleton state — shared across all composable instances */
const themeMode = ref<ThemeMode>(readStoredTheme())
const prefersDark = usePreferredDark()

function applyTheme(mode: ThemeMode, systemDark: boolean): void {
  const isDark = mode === 'dark' || (mode === 'system' && systemDark)
  if (isDark) {
    document.documentElement.classList.add('dark')
    document.documentElement.setAttribute('data-theme', 'dark')
  } else {
    document.documentElement.classList.remove('dark')
    document.documentElement.setAttribute('data-theme', 'light')
  }
}

// Reactively apply theme whenever mode or system preference changes
watchEffect(() => {
  applyTheme(themeMode.value, prefersDark.value)
})

/**
 * useTheme — composable for light/dark/system theme switching.
 *
 * Usage:
 *   const { themeMode, isDark, setTheme, toggleTheme } = useTheme()
 */
export function useTheme() {
  function setTheme(mode: ThemeMode): void {
    themeMode.value = mode
    localStorage.setItem(STORAGE_KEY, mode)
  }

  function toggleTheme(): void {
    const next: ThemeMode = themeMode.value === 'dark' ? 'light' : 'dark'
    setTheme(next)
  }

  const isDark = ref<boolean>(false)
  watchEffect(() => {
    isDark.value =
      themeMode.value === 'dark' ||
      (themeMode.value === 'system' && prefersDark.value)
  })

  return {
    themeMode,
    isDark,
    setTheme,
    toggleTheme,
  }
}
