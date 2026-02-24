import request from './request'

export interface OnlineUserVO {
  tokenId: string
  userId: number
  username: string
  nickname: string
  ip: string
  loginTime: string
}

export function getOnlineUserList(): Promise<OnlineUserVO[]> {
  return request.get<OnlineUserVO[]>('/api/v1/online-users')
}

export function forceLogout(tokenId: string): Promise<void> {
  return request.delete<void>(`/api/v1/online-users/${tokenId}`)
}
