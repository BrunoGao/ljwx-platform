import request from './request'
import type { Result, UserVO } from '@ljwx/shared'

export function getUserProfile(): Promise<Result<UserVO>> {
  return request.get('/api/v1/users/profile')
}

export function updateUserProfile(data: { nickname?: string; avatar?: string }): Promise<Result<void>> {
  return request.put('/api/v1/users/profile', data)
}
