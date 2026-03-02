import request from '@/api/request'
import type { PageResult, PageQuery } from '@ljwx/shared'

export interface OpenAppVO {
  id: number
  appKey: string
  appName: string
  appType: 'INTERNAL' | 'EXTERNAL'
  status: 'ENABLED' | 'DISABLED'
  rateLimit: number
  ipWhitelist?: string
  expireTime?: string
  createdTime: string
}

export interface OpenAppQueryDTO extends PageQuery {
  appName?: string
  appType?: string
  status?: string
}

export interface OpenAppCreateDTO {
  appName: string
  appType: 'INTERNAL' | 'EXTERNAL'
  rateLimit: number
  ipWhitelist?: string
  expireTime?: string
}

export interface OpenAppUpdateDTO {
  appName?: string
  rateLimit?: number
  ipWhitelist?: string
  expireTime?: string
}

export function getAppList(params?: OpenAppQueryDTO): Promise<PageResult<OpenAppVO>> {
  return request.get<PageResult<OpenAppVO>>('/api/v1/open-api/apps', { params })
}

export function getAppById(id: number): Promise<OpenAppVO> {
  return request.get<OpenAppVO>(`/api/v1/open-api/apps/${id}`)
}

export function createApp(data: OpenAppCreateDTO): Promise<OpenAppVO> {
  return request.post<OpenAppVO>('/api/v1/open-api/apps', data)
}

export function updateApp(id: number, data: OpenAppUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/open-api/apps/${id}`, data)
}

export function deleteApp(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/open-api/apps/${id}`)
}

export function regenerateSecret(id: number): Promise<string> {
  return request.post<string>(`/api/v1/open-api/apps/${id}/regenerate-secret`)
}
