import request from './request'
import type { ScreenOverviewVO, ScreenRealtimeVO, ScreenTrendVO } from '@ljwx/shared'

export function getScreenOverview(): Promise<ScreenOverviewVO> {
  return request.get('/api/v1/screen/overview') as Promise<ScreenOverviewVO>
}

export function getScreenRealtime(): Promise<ScreenRealtimeVO> {
  return request.get('/api/v1/screen/realtime') as Promise<ScreenRealtimeVO>
}

export function getScreenTrend(): Promise<ScreenTrendVO> {
  return request.get('/api/v1/screen/trend') as Promise<ScreenTrendVO>
}
