import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getTenantBrand, updateTenantBrand } from '@/api/tenantBrand'
import type { TenantBrandVO, TenantBrandUpdateDTO } from '@/api/tenantBrand'
import { ElMessage } from 'element-plus'

export const useTenantBrandStore = defineStore('tenantBrand', () => {
  const brand = ref<TenantBrandVO | null>(null)
  const loading = ref(false)

  /**
   * 加载品牌配置
   */
  async function loadBrand(): Promise<void> {
    loading.value = true
    try {
      brand.value = await getTenantBrand()
      applyBrand()
    } catch (error) {
      ElMessage.error('加载品牌配置失败')
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 更新品牌配置
   */
  async function updateBrand(data: TenantBrandUpdateDTO): Promise<void> {
    loading.value = true
    try {
      await updateTenantBrand(data)
      ElMessage.success('品牌配置更新成功')
      await loadBrand()
    } catch (error) {
      ElMessage.error('品牌配置更新失败')
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 应用品牌配置到页面
   */
  function applyBrand(): void {
    if (!brand.value) return

    // 应用主题色
    if (brand.value.primaryColor) {
      document.documentElement.style.setProperty('--el-color-primary', brand.value.primaryColor)
    }

    // 应用 Favicon
    if (brand.value.faviconUrl) {
      const favicon = document.querySelector<HTMLLinkElement>('link[rel="icon"]')
      if (favicon) {
        favicon.href = brand.value.faviconUrl
      } else {
        const newFavicon = document.createElement('link')
        newFavicon.rel = 'icon'
        newFavicon.href = brand.value.faviconUrl
        document.head.appendChild(newFavicon)
      }
    }

    // 应用页面标题
    if (brand.value.brandName) {
      document.title = brand.value.brandName
    }

    // 应用自定义 CSS
    if (brand.value.customCss) {
      const existingStyle = document.getElementById('tenant-custom-css')
      if (existingStyle) {
        existingStyle.textContent = brand.value.customCss
      } else {
        const style = document.createElement('style')
        style.id = 'tenant-custom-css'
        style.textContent = brand.value.customCss
        document.head.appendChild(style)
      }
    }
  }

  return {
    brand,
    loading,
    loadBrand,
    updateBrand,
    applyBrand,
  }
})
