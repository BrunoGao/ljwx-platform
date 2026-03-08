import request from './request'
import type {
  PageResult,
  TenantVO,
  TenantQueryDTO,
  TenantCreateDTO,
  TenantUpdateDTO,
  TenantFreezeDTO,
  TenantCancelDTO,
} from '@ljwx/shared'

/**
 * 获取租户列表（分页）
 */
export function getTenantList(params?: TenantQueryDTO): Promise<PageResult<TenantVO>> {
  return request.get<PageResult<TenantVO>>('/api/v1/tenants', { params })
}

/**
 * 创建租户
 */
export function createTenant(data: TenantCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/tenants', data)
}

/**
 * 更新租户
 */
export function updateTenant(id: number, data: TenantUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/tenants/${id}`, data)
}

/**
 * 冻结租户
 */
export function freezeTenant(id: number, data: TenantFreezeDTO): Promise<void> {
  return request.post<void>(`/api/v1/tenants/${id}/freeze`, data)
}

/**
 * 解冻租户
 */
export function unfreezeTenant(id: number): Promise<void> {
  return request.post<void>(`/api/v1/tenants/${id}/unfreeze`)
}

/**
 * 注销租户
 */
export function cancelTenant(id: number, data: TenantCancelDTO): Promise<void> {
  return request.post<void>(`/api/v1/tenants/${id}/cancel`, data)
}

/**
 * 初始化租户
 */
export function initializeTenant(id: number): Promise<void> {
  return request.post<void>(`/api/v1/tenants/${id}/initialize`)
}
