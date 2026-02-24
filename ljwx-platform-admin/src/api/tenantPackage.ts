import request from './request'
import type {
  PageResult,
  TenantPackageVO,
  TenantPackageQueryDTO,
  TenantPackageCreateDTO,
  TenantPackageUpdateDTO,
} from '@ljwx/shared'

/**
 * 获取租户套餐列表（分页）
 */
export function getTenantPackageList(
  params?: TenantPackageQueryDTO,
): Promise<PageResult<TenantPackageVO>> {
  return request.get<PageResult<TenantPackageVO>>('/api/v1/tenant-packages', { params })
}

/**
 * 创建租户套餐
 */
export function createTenantPackage(data: TenantPackageCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/tenant-packages', data)
}

/**
 * 更新租户套餐
 */
export function updateTenantPackage(id: number, data: TenantPackageUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/tenant-packages/${id}`, data)
}

/**
 * 删除租户套餐
 */
export function deleteTenantPackage(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/tenant-packages/${id}`)
}
