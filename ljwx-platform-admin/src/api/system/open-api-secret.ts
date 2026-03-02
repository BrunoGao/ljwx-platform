import request from '@/api/request'

export interface OpenAppSecretVO {
  id: number
  appId: number
  secretKey: string
  secretVersion: number
  status: 'ACTIVE' | 'EXPIRED'
  expireTime?: string
  createdTime: string
}

export interface OpenAppSecretDTO {
  appId: number
  validDays?: number
}

export function createSecret(appId: number, data: OpenAppSecretDTO): Promise<OpenAppSecretVO> {
  return request.post(`/api/v1/open-api/apps/${appId}/secrets`, data)
}

export function rotateSecret(appId: number, id: number): Promise<OpenAppSecretVO> {
  return request.put(`/api/v1/open-api/apps/${appId}/secrets/${id}/rotate`)
}

export function deleteSecret(appId: number, id: number): Promise<void> {
  return request.delete(`/api/v1/open-api/apps/${appId}/secrets/${id}`)
}

export function listSecrets(appId: number): Promise<OpenAppSecretVO[]> {
  return request.get(`/api/v1/open-api/apps/${appId}/secrets`)
}
