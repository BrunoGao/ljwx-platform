import request from '@/api/request'

export interface ServerInfoVO {
  cpuUsage: number
  cpuCores: number
  memTotal: number
  memUsed: number
  memUsage: number
  diskTotal: number
  diskUsed: number
  diskUsage: number
  osName: string
  osArch: string
  hostname: string
}

export interface JvmInfoVO {
  heapUsed: number
  heapMax: number
  heapUsage: number
  nonHeapUsed: number
  gcCount: number
  gcTime: number
  jvmVersion: string
  startTime: string
  uptime: number
}

export interface CacheStatsVO {
  cacheName: string
  hitCount: number
  missCount: number
  hitRate: number
  size: number
}

export function getServerInfo(): Promise<ServerInfoVO> {
  return request.get<ServerInfoVO>('/api/v1/monitor/server')
}

export function getJvmInfo(): Promise<JvmInfoVO> {
  return request.get<JvmInfoVO>('/api/v1/monitor/jvm')
}

export function getCacheStats(): Promise<CacheStatsVO[]> {
  return request.get<CacheStatsVO[]>('/api/v1/monitor/cache')
}
