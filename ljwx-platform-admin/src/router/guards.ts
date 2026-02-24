import type { Router } from 'vue-router'
import NProgress from 'nprogress'
import { useUserStore } from '@/stores/user'
import { usePermissionStore } from '@/stores/permission'

/**
 * Register all global navigation guards on the router instance.
 * Call this once after createRouter(), before app.use(router).
 */
export function setupRouterGuards(router: Router): void {
  router.beforeEach((to) => {
    NProgress.start()

    const userStore = useUserStore()
    const permissionStore = usePermissionStore()

    // Redirect to login if route requires auth and no token
    if (to.meta.requiresAuth && !userStore.accessToken) {
      return { name: 'Login', query: { redirect: to.fullPath } }
    }

    // Redirect authenticated users away from login page
    if (to.name === 'Login' && userStore.accessToken) {
      return { path: '/dashboard' }
    }

    // Build accessible routes once after login
    if (userStore.accessToken && !permissionStore.hasRoutes) {
      const allRoutes = router.getRoutes()
      // Filter to only child routes of the root layout (requiresAuth routes)
      const layoutRoutes = allRoutes.filter(
        (r) => r.meta.requiresAuth === true && r.path !== '/',
      )
      permissionStore.buildAccessibleRoutes(layoutRoutes)
    }

    // Check per-route authority if defined
    const authority = to.meta.authority as string | undefined
    if (authority && userStore.accessToken) {
      const userStore2 = useUserStore()
      if (!userStore2.hasAuthority(authority)) {
        return { path: '/403' }
      }
    }
  })

  router.afterEach(() => {
    NProgress.done()
  })
}
