import { useUserStore } from '@/stores/user'

/**
 * usePermission — composable for checking RBAC authorities in templates and scripts.
 *
 * Usage:
 *   const { hasPermission } = usePermission()
 *   if (hasPermission('user:write')) { ... }
 *
 *   In template:
 *   <el-button v-if="hasPermission('user:delete')">删除</el-button>
 */
export function usePermission() {
  const userStore = useUserStore()

  /**
   * Returns true if the current user has ALL of the given authorities.
   */
  function hasPermission(...authorities: string[]): boolean {
    return authorities.every((auth) => userStore.hasAuthority(auth))
  }

  /**
   * Returns true if the current user has ANY of the given authorities.
   */
  function hasAnyPermission(...authorities: string[]): boolean {
    return authorities.some((auth) => userStore.hasAuthority(auth))
  }

  return {
    hasPermission,
    hasAnyPermission,
  }
}
