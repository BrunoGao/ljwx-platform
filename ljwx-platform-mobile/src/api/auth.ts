import request from './request'
import type { Result } from '@ljwx/shared'

export interface LoginDTO {
  username: string
  password: string
}

export interface TokenVO {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

export interface RefreshDTO {
  refreshToken: string
}

export function login(data: LoginDTO): Promise<TokenVO> {
  return request.post<unknown, TokenVO, LoginDTO>('/auth/login', data)
}

export function refreshToken(data: RefreshDTO): Promise<TokenVO> {
  return request.post<unknown, TokenVO, RefreshDTO>('/auth/refresh', data)
}

export function logout(): Promise<Result<void>> {
  return request.post('/auth/logout')
}
