import request from './request'

export interface ProfileVO {
  id: number
  username: string
  nickname: string
  email: string
  phone: string
  avatar: string
  createdTime: string
}

export interface ProfileUpdateDTO {
  nickname?: string
  email?: string
  phone?: string
  avatar?: string
}

export interface PasswordUpdateDTO {
  oldPassword: string
  newPassword: string
}

export function getProfile(): Promise<ProfileVO> {
  return request.get<ProfileVO>('/api/v1/profile')
}

export function updateProfile(data: ProfileUpdateDTO): Promise<void> {
  return request.put<void>('/api/v1/profile', data)
}

export function updatePassword(data: PasswordUpdateDTO): Promise<void> {
  return request.put<void>('/api/v1/profile/password', data)
}
