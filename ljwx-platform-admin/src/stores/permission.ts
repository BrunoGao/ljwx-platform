import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'

/**
 * Route permission metadata — extends RouteMeta defined in router/index.ts
 */
export interface PermissionRoute {
  path: string
  name?: string
  title?: string
  icon?: string
  hidden?: boolean
  authority?: string
  children?: PermissionRoute[]
}

export const usePermissionStore = defineStore('permission', () => {
  const userStore = useUserStore()

  /** All static routes that require permission filtering */
  const allRoutes = ref<RouteRecordRaw[]>([])

  /** Routes accessible to the current user after filtering */
  const accessibleRoutes = ref<RouteRecordRaw[]>([])

  /** Whether dynamic routes have been loaded */
  const routesLoaded = ref<boolean>(false)

  const hasRoutes = computed(() => routesLoaded.value)

  /**
   * Check if the current user has a given authority string.
   * Delegates to userStore.hasAuthority.
   */
  function canAccess(authority: string): boolean {
    return userStore.hasAuthority(authority)
  }

  /**
   * Filter a list of routes based on the current user's authorities.
   * A route is accessible if it has no `authority` meta or the user has that authority.
   */
  function filterRoutes(routes: RouteRecordRaw[]): RouteRecordRaw[] {
    return routes.reduce<RouteRecordRaw[]>((acc, route) => {
      const authority = route.meta?.authority as string | undefined
      if (authority && !userStore.hasAuthority(authority)) {
        return acc
      }
      const filtered: RouteRecordRaw = { ...route }
      if (filtered.children && filtered.children.length > 0) {
        filtered.children = filterRoutes(filtered.children)
      }
      acc.push(filtered)
      return acc
    }, [])
  }

  /**
   * Build accessible routes from the full route list.
   * Call this after the user has logged in and userInfo is populated.
   */
  function buildAccessibleRoutes(routes: RouteRecordRaw[]): void {
    allRoutes.value = routes
    accessibleRoutes.value = filterRoutes(routes)
    routesLoaded.value = true
  }

  function reset(): void {
    allRoutes.value = []
    accessibleRoutes.value = []
    routesLoaded.value = false
  }

  return {
    allRoutes,
    accessibleRoutes,
    routesLoaded,
    hasRoutes,
    canAccess,
    filterRoutes,
    buildAccessibleRoutes,
    reset,
  }
})
