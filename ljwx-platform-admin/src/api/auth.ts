import request from './request'
import type { LoginDTO, LoginVO, TokenVO, UserInfo } from '@ljwx/shared'

/**
 * 用户登录
 */
export function loginApi(data: LoginDTO): Promise<LoginVO> {
  return request.post<LoginVO>('/api/auth/login', data)
}

/**
 * 用户登出
 */
export function logoutApi(): Promise<void> {
  return request.post<void>('/api/auth/logout')
}

/**
 * 刷新 Token
 */
export function refreshTokenApi(refreshToken: string): Promise<TokenVO> {
  return request.post<TokenVO>('/api/auth/refresh', { refreshToken })
}

/**
 * 获取当前用户信息
 */
export function getUserInfoApi(): Promise<UserInfo> {
  return request.get<UserInfo>('/api/auth/me')
}
