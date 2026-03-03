import request from '../request'

export interface UsageRecordVO {
  id: number
  metricType: string
  usageValue: number
  recordDate: string
}

export interface TenantUsageSummaryVO {
  tenantId: number
  tenantName: string
  expireTime: string
  userCount: number
  storageMb: number
  apiCallsTotal: number
  loginCountLast30d: number
  isExpiringSoon: boolean
}

export interface BillingQueryDTO {
  startDate: string
  endDate: string
  metricType?: string
}

/**
 * 获取用量记录
 */
export function getUsageRecords(params: BillingQueryDTO): Promise<UsageRecordVO[]> {
  return request.get<UsageRecordVO[]>('/api/v1/billing/usage', { params })
}

/**
 * 获取租户用量汇总（仅超管）
 */
export function getTenantUsageSummary(): Promise<TenantUsageSummaryVO[]> {
  return request.get<TenantUsageSummaryVO[]>('/api/v1/billing/summary')
}
