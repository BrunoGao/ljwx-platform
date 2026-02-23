<script setup lang="ts">
import { computed } from 'vue'
import { useAppStore } from '@/stores/app'
import Sidebar from './components/Sidebar.vue'
import Navbar from './components/Navbar.vue'

const appStore = useAppStore()
const isCollapsed = computed(() => appStore.sidebarCollapsed)
</script>

<template>
  <el-container class="layout-wrapper">
    <el-aside
      class="layout-sidebar"
      :width="isCollapsed ? '64px' : '220px'"
    >
      <Sidebar />
    </el-aside>
    <el-container class="layout-main">
      <el-header class="layout-header" height="56px">
        <Navbar />
      </el-header>
      <el-main class="layout-content">
        <RouterView />
      </el-main>
    </el-container>
  </el-container>
</template>

<style scoped lang="scss">
.layout-wrapper {
  height: 100vh;
  overflow: hidden;
}

.layout-sidebar {
  background-color: var(--sidebar-bg, #001529);
  transition: width 0.3s ease;
  overflow: hidden;
  flex-shrink: 0;
}

.layout-main {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.layout-header {
  background-color: #fff;
  border-bottom: 1px solid #e8e8e8;
  padding: 0;
  display: flex;
  align-items: center;
  box-shadow: 0 1px 4px rgba(0, 21, 41, 0.08);
  z-index: 10;
}

.layout-content {
  flex: 1;
  overflow: auto;
  background-color: #f0f2f5;
  padding: 16px;
}
</style>
