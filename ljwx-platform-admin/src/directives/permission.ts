import type { Directive } from 'vue'
import { useUserStore } from '@/stores/user'

/**
 * v-permission directive
 *
 * Usage:
 *   <el-button v-permission="'user:write'">编辑</el-button>
 *   <el-button v-permission="['user:write', 'user:delete']">操作</el-button>
 *
 * If the user does not have the required permission(s), the element will be removed from DOM.
 */
export const vPermission: Directive<HTMLElement, string | string[]> = {
  mounted(el, binding) {
    const userStore = useUserStore()
    const required = Array.isArray(binding.value) ? binding.value : [binding.value]
    const hasPermission = required.some(p => userStore.hasAuthority(p))
    if (!hasPermission) {
      el.parentNode?.removeChild(el)
    }
  }
}
