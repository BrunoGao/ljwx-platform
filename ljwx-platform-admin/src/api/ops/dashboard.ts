import request from '../request'
import type { TenantUsageSummaryVO } from '../billing/billing'

export interface DailyStatVO {
  date: string
  count: number
}

export interface OperationsDashboardVO {
  totalTenants: number
  activeTenants: number
  expiringSoon: TenantUsageSummaryVO[]
  dailyActiveUsers: DailyStatVO[]
  totalStorageMb: number
  totalApiCallsToday: number
}

/**
 * 获取运营仪表盘数据（仅超管）
 */
export function getOperationsDashboard(): Promise<OperationsDashboardVO> {
  return request.get<OperationsDashboardVO>('/api/v1/ops/dashboard')
}
