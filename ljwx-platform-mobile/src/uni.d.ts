/**
 * uni-app global API type declarations (minimal scaffold)
 * Full types provided by @dcloudio/types after pnpm install
 */

interface UniShowToastOptions {
  title: string
  icon?: 'success' | 'error' | 'loading' | 'none'
  duration?: number
  mask?: boolean
  success?: () => void
  fail?: () => void
  complete?: () => void
}

interface UniShowModalOptions {
  title?: string
  content?: string
  showCancel?: boolean
  cancelText?: string
  confirmText?: string
  success?: (res: { confirm: boolean; cancel: boolean }) => void
  fail?: () => void
  complete?: () => void
}

interface UniNavigateOptions {
  url: string
  success?: () => void
  fail?: () => void
  complete?: () => void
}

interface UniStorageOptions {
  key: string
  data?: unknown
  success?: () => void
  fail?: () => void
  complete?: () => void
}

declare const uni: {
  showToast(options: UniShowToastOptions): void
  showModal(options: UniShowModalOptions): void
  navigateTo(options: UniNavigateOptions): void
  redirectTo(options: UniNavigateOptions): void
  reLaunch(options: UniNavigateOptions): void
  switchTab(options: UniNavigateOptions): void
  navigateBack(options?: { delta?: number }): void
  setStorageSync(key: string, data: unknown): void
  getStorageSync(key: string): unknown
  removeStorageSync(key: string): void
  stopPullDownRefresh(): void
}

// uni-app lifecycle hooks (global functions in <script setup>)
declare function onLaunch(hook: () => void): void
declare function onShow(hook: () => void): void
declare function onHide(hook: () => void): void
declare function onLoad(hook: (options?: Record<string, string>) => void): void
declare function onReady(hook: () => void): void
declare function onUnload(hook: () => void): void
declare function onPullDownRefresh(hook: () => void): void
declare function onReachBottom(hook: () => void): void
