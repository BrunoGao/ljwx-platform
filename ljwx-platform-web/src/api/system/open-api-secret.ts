import request from '@/api/request'
import type { Result } from '@ljwx/shared'

export interface OpenAppSecretVO {
  id: number
  appId: number
  secretKey: string
  secretVersion: number
  status: string
  expireTime: string | null
  createdTime: string
}

export interface OpenAppSecretDTO {
  appId: number
  validDays?: number
}

export function createSecret(appId: number, data: OpenAppSecretDTO): Promise<Result<OpenAppSecretVO>> {
  return request.post(`/api/v1/open-api/apps/${appId}/secrets`, data)
}

export function rotateSecret(appId: number, id: number): Promise<Result<OpenAppSecretVO>> {
  return request.put(`/api/v1/open-api/apps/${appId}/secrets/${id}/rotate`)
}

export function deleteSecret(appId: number, id: number): Promise<Result<void>> {
  return request.delete(`/api/v1/open-api/apps/${appId}/secrets/${id}`)
}

export function listSecrets(appId: number): Promise<Result<OpenAppSecretVO[]>> {
  return request.get(`/api/v1/open-api/apps/${appId}/secrets`)
}
