import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { MenuTreeVO } from '@ljwx/shared'
import { getMenuTree } from '@/api/menu'

export const useMenuStore = defineStore('menu', () => {
  const menuTree = ref<MenuTreeVO[]>([])
  const loading = ref(false)

  async function fetchMenuTree(): Promise<void> {
    loading.value = true
    try {
      menuTree.value = await getMenuTree()
    } finally {
      loading.value = false
    }
  }

  return { menuTree, loading, fetchMenuTree }
})
