import request from './request'
import type {
  PageResult,
  RoleVO,
  RoleQueryDTO,
  RoleCreateDTO,
  RoleUpdateDTO,
  PermissionVO,
} from '@ljwx/shared'

/**
 * 获取角色列表（分页）
 */
export function getRoleList(params?: RoleQueryDTO): Promise<PageResult<RoleVO>> {
  return request.get<PageResult<RoleVO>>('/api/roles', { params })
}

/**
 * 创建角色
 */
export function createRole(data: RoleCreateDTO): Promise<number> {
  return request.post<number>('/api/roles', data)
}

/**
 * 更新角色
 */
export function updateRole(id: number, data: RoleUpdateDTO): Promise<void> {
  return request.put<void>(`/api/roles/${id}`, data)
}

/**
 * 删除角色
 */
export function deleteRole(id: number): Promise<void> {
  return request.delete<void>(`/api/roles/${id}`)
}

/**
 * 获取权限列表
 */
export function getPermissionList(): Promise<PermissionVO[]> {
  return request.get<PermissionVO[]>('/api/permissions')
}
