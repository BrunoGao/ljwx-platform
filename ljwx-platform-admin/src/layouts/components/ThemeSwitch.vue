<script setup lang="ts">
import { computed } from 'vue'
import { Sunny, Moon } from '@element-plus/icons-vue'
import { useTheme } from '@/composables/useTheme'

const { isDark, toggleTheme } = useTheme()

const tooltip = computed(() => (isDark.value ? '切换到亮色模式' : '切换到暗色模式'))
</script>

<template>
  <el-tooltip :content="tooltip" placement="bottom">
    <el-icon
      class="theme-switch"
      :size="20"
      @click="toggleTheme"
    >
      <Moon v-if="isDark" />
      <Sunny v-else />
    </el-icon>
  </el-tooltip>
</template>

<style scoped lang="scss">
.theme-switch {
  cursor: pointer;
  color: var(--el-text-color-regular);
  transition: color 0.2s;

  &:hover {
    color: var(--el-color-primary);
  }
}
</style>
