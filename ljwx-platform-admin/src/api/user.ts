import request from './request'
import type {
  PageResult,
  UserVO,
  UserQueryDTO,
  UserCreateDTO,
  UserUpdateDTO,
} from '@ljwx/shared'

/**
 * 获取用户列表（分页）
 */
export function getUserList(params?: UserQueryDTO): Promise<PageResult<UserVO>> {
  return request.get<PageResult<UserVO>>('/api/v1/users', { params })
}

/**
 * 创建用户
 */
export function createUser(data: UserCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/users', data)
}

/**
 * 更新用户
 */
export function updateUser(id: number, data: UserUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/users/${id}`, data)
}

/**
 * 删除用户
 */
export function deleteUser(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/users/${id}`)
}
