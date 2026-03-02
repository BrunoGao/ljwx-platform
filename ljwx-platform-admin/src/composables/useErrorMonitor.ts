import request from '@/api/request'

interface FrontendErrorDTO {
  errorMessage: string
  stackTrace: string
  pageUrl: string
  userAgent: string
}

/**
 * 前端错误监控组合式函数
 *
 * 捕获全局 JavaScript 错误和未处理的 Promise rejection，
 * 上报至后端 POST /api/v1/frontend-errors（Phase 29）。
 *
 * 防抖策略：以错误 message 为 key，同一错误 5 秒内只上报一次。
 */
export function useErrorMonitor() {
  // 防抖 Map：key = errorMessage, value = 最后上报时间戳
  const errorDebounceMap = new Map<string, number>()
  const DEBOUNCE_WINDOW = 5000 // 5 秒

  function shouldReport(errorMessage: string): boolean {
    const now = Date.now()
    const lastReportTime = errorDebounceMap.get(errorMessage)

    if (lastReportTime && now - lastReportTime < DEBOUNCE_WINDOW) {
      return false
    }

    errorDebounceMap.set(errorMessage, now)
    return true
  }

  function reportError(dto: FrontendErrorDTO): void {
    if (!shouldReport(dto.errorMessage)) {
      return
    }

    request
      .post<void>('/api/v1/frontend-errors', dto)
      .catch(() => {
        // 上报失败静默处理，不影响用户体验
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

  function init(): void {
    window.addEventListener('error', handleError)
    window.addEventListener('unhandledrejection', handleUnhandledRejection)
  }

  function cleanup(): void {
    window.removeEventListener('error', handleError)
    window.removeEventListener('unhandledrejection', handleUnhandledRejection)
    errorDebounceMap.clear()
  }

  return {
    init,
    cleanup,
  }
}
