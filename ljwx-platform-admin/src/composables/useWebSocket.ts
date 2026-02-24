import { ref, onUnmounted } from 'vue'
import { useUserStore } from '@/stores/user'

export interface WsMessage {
  type: string
  content: string
  timestamp: number
}

export interface UseWebSocketOptions {
  /** Reconnect delay in ms (default: 3000) */
  reconnectDelay?: number
  /** Max reconnect attempts (default: 5, 0 = unlimited) */
  maxRetries?: number
}

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const { reconnectDelay = 3000, maxRetries = 5 } = options

  const connected = ref(false)
  const messages = ref<WsMessage[]>([])
  const error = ref<string | null>(null)

  let ws: WebSocket | null = null
  let retryCount = 0
  let retryTimer: ReturnType<typeof setTimeout> | null = null
  let manualClose = false

  function buildUrl(): string {
    const userStore = useUserStore()
    const token = userStore.accessToken
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = window.location.host
    return `${protocol}//${host}/ws/notifications?token=${encodeURIComponent(token)}`
  }

  function connect(): void {
    if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
      return
    }
    manualClose = false
    error.value = null

    try {
      ws = new WebSocket(buildUrl())
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'WebSocket 连接失败'
      scheduleReconnect()
      return
    }

    ws.onopen = () => {
      connected.value = true
      retryCount = 0
      error.value = null
    }

    ws.onmessage = (event: MessageEvent) => {
      try {
        const msg = JSON.parse(event.data as string) as WsMessage
        messages.value = [msg, ...messages.value].slice(0, 100)
      } catch {
        // ignore malformed messages
      }
    }

    ws.onerror = () => {
      error.value = 'WebSocket 连接异常'
    }

    ws.onclose = () => {
      connected.value = false
      ws = null
      if (!manualClose) {
        scheduleReconnect()
      }
    }
  }

  function scheduleReconnect(): void {
    if (maxRetries > 0 && retryCount >= maxRetries) {
      error.value = `已达最大重连次数 (${maxRetries})`
      return
    }
    retryCount++
    retryTimer = setTimeout(() => {
      connect()
    }, reconnectDelay)
  }

  function disconnect(): void {
    manualClose = true
    if (retryTimer !== null) {
      clearTimeout(retryTimer)
      retryTimer = null
    }
    if (ws) {
      ws.close()
      ws = null
    }
    connected.value = false
  }

  function clearMessages(): void {
    messages.value = []
  }

  onUnmounted(() => {
    disconnect()
  })

  return {
    connected,
    messages,
    error,
    connect,
    disconnect,
    clearMessages,
  }
}
