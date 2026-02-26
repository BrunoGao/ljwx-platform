import { onMounted, onUnmounted } from 'vue'
import request from '@/api/request'

interface FrontendErrorDTO {
  errorMessage: string
  stackTrace: string
  pageUrl: string
  userAgent: string
}

/**
 * 前端错误监控组合式函数。
 *
 * 捕获全局 JavaScript 错误和未处理的 Promise rejection，
 * 上报至后端 POST /api/v1/frontend-errors（Phase 29）。
 * 上报失败时静默忽略，不影响用户体验。
 */
export function useErrorMonitor() {
  function reportError(dto: FrontendErrorDTO): void {
    request
      .post('/api/v1/frontend-errors', dto)
      .catch(() => {
        // 上报失败静默处理
      })
  }

  function handleError(event: ErrorEvent): void {
    reportError({
      errorMessage: event.message ?? 'Unknown error',
      stackTrace: event.error?.stack ?? '',
      pageUrl: window.location.href,
      userAgent: navigator.userAgent,
    })
  }

  function handleUnhandledRejection(event: PromiseRejectionEvent): void {
    const reason = event.reason
    const message =
      reason instanceof Error ? reason.message : String(reason ?? 'Unhandled rejection')
    const stack = reason instanceof Error ? (reason.stack ?? '') : ''

    reportError({
      errorMessage: message,
      stackTrace: stack,
      pageUrl: window.location.href,
      userAgent: navigator.userAgent,
    })
  }

  onMounted(() => {
    window.addEventListener('error', handleError)
    window.addEventListener('unhandledrejection', handleUnhandledRejection)
  })

  onUnmounted(() => {
    window.removeEventListener('error', handleError)
    window.removeEventListener('unhandledrejection', handleUnhandledRejection)
  })
}
