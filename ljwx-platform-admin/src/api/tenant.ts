import request from './request'
import type {
  PageResult,
  TenantVO,
  TenantQueryDTO,
  TenantCreateDTO,
  TenantUpdateDTO,
} from '@ljwx/shared'

/**
 * 获取租户列表（分页）
 */
export function getTenantList(params?: TenantQueryDTO): Promise<PageResult<TenantVO>> {
  return request.get<PageResult<TenantVO>>('/api/tenants', { params })
}

/**
 * 创建租户
 */
export function createTenant(data: TenantCreateDTO): Promise<number> {
  return request.post<number>('/api/tenants', data)
}

/**
 * 更新租户
 */
export function updateTenant(id: number, data: TenantUpdateDTO): Promise<void> {
  return request.put<void>(`/api/tenants/${id}`, data)
}
