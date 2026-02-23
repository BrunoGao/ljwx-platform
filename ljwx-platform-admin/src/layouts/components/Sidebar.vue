<script setup lang="ts">
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const router = useRouter()
const route = useRoute()

const isCollapsed = computed(() => appStore.sidebarCollapsed)

interface MenuItem {
  name: string
  path: string
  icon: string
  title: string
}

const menuItems: MenuItem[] = [
  { name: 'Dashboard', path: '/dashboard', icon: 'Odometer', title: '仪表盘' },
]

function isActive(path: string): boolean {
  return route.path === path || route.path.startsWith(path + '/')
}

function navigateTo(path: string): void {
  router.push(path)
}
</script>

<template>
  <div class="sidebar-container">
    <div class="sidebar-logo">
      <el-icon class="logo-icon" :size="28" color="#fff">
        <Grid />
      </el-icon>
      <transition name="logo-text">
        <span v-if="!isCollapsed" class="logo-text">LJWX Platform</span>
      </transition>
    </div>
    <el-menu
      :collapse="isCollapsed"
      :default-active="route.path"
      background-color="#001529"
      text-color="rgba(255,255,255,0.65)"
      active-text-color="#fff"
      class="sidebar-menu"
    >
      <el-menu-item
        v-for="item in menuItems"
        :key="item.name"
        :index="item.path"
        @click="navigateTo(item.path)"
        :class="{ 'is-active': isActive(item.path) }"
      >
        <el-icon>
          <component :is="item.icon" />
        </el-icon>
        <template #title>{{ item.title }}</template>
      </el-menu-item>
    </el-menu>
  </div>
</template>

<style scoped lang="scss">
.sidebar-container {
  height: 100%;
  display: flex;
  flex-direction: column;
  background-color: #001529;
  overflow: hidden;
}

.sidebar-logo {
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background-color: #002040;
  flex-shrink: 0;
  overflow: hidden;
  padding: 0 16px;
}

.logo-text {
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
}

.logo-text-enter-active,
.logo-text-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.logo-text-enter-from,
.logo-text-leave-to {
  opacity: 0;
  transform: translateX(-10px);
}

.sidebar-menu {
  flex: 1;
  border-right: none;
  overflow-y: auto;
  overflow-x: hidden;

  &:not(.el-menu--collapse) {
    width: 220px;
  }
}
</style>
