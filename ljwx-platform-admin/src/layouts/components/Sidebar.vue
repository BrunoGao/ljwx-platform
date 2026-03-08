<script setup lang="ts">
import { computed } from 'vue'
import type { Component } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import type { RouteRecordNormalized } from 'vue-router'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import { Grid, Menu as MenuIcon } from '@element-plus/icons-vue'
import { useAppStore } from '@/stores/app'
import { usePermissionStore } from '@/stores/permission'

const appStore = useAppStore()
const permissionStore = usePermissionStore()
const router = useRouter()
const route = useRoute()

const isCollapsed = computed(() => appStore.sidebarCollapsed)

interface SidebarItem {
  index: string
  path?: string
  title: string
  icon: Component
  children?: SidebarItem[]
}

const groupMeta: Record<string, { title: string; icon: Component }> = {
  system: { title: '系统管理', icon: ElementPlusIconsVue.Setting },
  monitor: { title: '系统监控', icon: ElementPlusIconsVue.Monitor },
  ops: { title: '运营中心', icon: ElementPlusIconsVue.DataAnalysis },
  report: { title: '报表中心', icon: ElementPlusIconsVue.PieChart },
  workflow: { title: '工作流', icon: ElementPlusIconsVue.Connection },
  form: { title: '表单中心', icon: ElementPlusIconsVue.EditPen },
  message: { title: '消息中心', icon: ElementPlusIconsVue.ChatDotRound },
  billing: { title: '计费中心', icon: ElementPlusIconsVue.Coin },
  tenant: { title: '租户中心', icon: ElementPlusIconsVue.OfficeBuilding },
}

function normalizePath(path: string): string {
  if (!path) {
    return '/'
  }
  return path.startsWith('/') ? path : `/${path}`
}

function getRouteTitle(routeRecord: RouteRecordNormalized): string {
  return String(routeRecord.meta.title || routeRecord.name || routeRecord.path)
}

function resolveIcon(iconName: unknown, fallback: Component = MenuIcon): Component {
  if (typeof iconName === 'string' && iconName in ElementPlusIconsVue) {
    return ElementPlusIconsVue[iconName as keyof typeof ElementPlusIconsVue]
  }
  return fallback
}

function getCandidateRoutes(): RouteRecordNormalized[] {
  if (permissionStore.accessibleRoutes.length > 0) {
    return permissionStore.accessibleRoutes as RouteRecordNormalized[]
  }

  return router.getRoutes().filter((routeRecord) => (
    routeRecord.meta.requiresAuth === true &&
    routeRecord.path !== '/' &&
    !routeRecord.redirect
  ))
}

const menuItems = computed<SidebarItem[]>(() => {
  const grouped = new Map<string, SidebarItem>()
  const topLevelItems: SidebarItem[] = []

  for (const routeRecord of getCandidateRoutes()) {
    if (routeRecord.meta.hidden) {
      continue
    }

    const absolutePath = normalizePath(routeRecord.path)
    const segments = absolutePath.replace(/^\/+/, '').split('/').filter(Boolean)

    if (segments.length <= 1) {
      topLevelItems.push({
        index: absolutePath,
        path: absolutePath,
        title: getRouteTitle(routeRecord),
        icon: resolveIcon(routeRecord.meta.icon, MenuIcon),
      })
      continue
    }

    const groupKey = segments[0]
    const meta = groupMeta[groupKey] ?? {
      title: groupKey,
      icon: resolveIcon(routeRecord.meta.icon, MenuIcon),
    }

    const groupIndex = `group:${groupKey}`
    if (!grouped.has(groupIndex)) {
      grouped.set(groupIndex, {
        index: groupIndex,
        title: meta.title,
        icon: meta.icon,
        children: [],
      })
    }

    grouped.get(groupIndex)!.children!.push({
      index: absolutePath,
      path: absolutePath,
      title: getRouteTitle(routeRecord),
      icon: resolveIcon(routeRecord.meta.icon, meta.icon),
    })
  }

  return [...topLevelItems, ...grouped.values()]
})

const defaultOpeneds = computed(() => {
  const openGroups = new Set<string>()
  for (const item of menuItems.value) {
    if (item.children?.some((child) => child.path && isActive(child.path))) {
      openGroups.add(item.index)
    }
  }
  return [...openGroups]
})

function isActive(path: string): boolean {
  return route.path === path || route.path.startsWith(`${path}/`)
}

function navigateTo(path?: string): void {
  if (!path || route.path === path) {
    return
  }
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
      :default-openeds="defaultOpeneds"
      background-color="#001529"
      text-color="rgba(255,255,255,0.65)"
      active-text-color="#fff"
      class="sidebar-menu"
    >
      <template v-for="item in menuItems" :key="item.index">
        <el-sub-menu v-if="item.children?.length" :index="item.index">
          <template #title>
            <el-icon>
              <component :is="item.icon" />
            </el-icon>
            <span>{{ item.title }}</span>
          </template>
          <el-menu-item
            v-for="child in item.children"
            :key="child.index"
            :index="child.index"
            :class="{ 'is-active': child.path ? isActive(child.path) : false }"
            @click="navigateTo(child.path)"
          >
            <el-icon>
              <component :is="child.icon" />
            </el-icon>
            <template #title>{{ child.title }}</template>
          </el-menu-item>
        </el-sub-menu>
        <el-menu-item
          v-else
          :index="item.index"
          :class="{ 'is-active': item.path ? isActive(item.path) : false }"
          @click="navigateTo(item.path)"
        >
          <el-icon>
            <component :is="item.icon" />
          </el-icon>
          <template #title>{{ item.title }}</template>
        </el-menu-item>
      </template>
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
