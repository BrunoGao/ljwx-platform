import request from '@/api/request'
import type { Result, PageResult, PageQuery } from '@ljwx/shared'

export interface WebhookConfigVO {
  id: number
  webhookName: string
  webhookUrl: string
  eventTypes: string[]
  status: 'ENABLED' | 'DISABLED'
  retryCount: number
  timeoutSeconds: number
  createdTime: string
  updatedTime: string
}

export interface WebhookConfigDTO {
  webhookName: string
  webhookUrl: string
  eventTypes: string[]
  secretKey: string
  status: 'ENABLED' | 'DISABLED'
  retryCount?: number
  timeoutSeconds?: number
}

export interface WebhookConfigQueryDTO extends PageQuery {
  webhookName?: string
  status?: string
}

export interface WebhookLogVO {
  id: number
  webhookId: number
  webhookName: string
  eventType: string
  eventData: string
  requestUrl: string
  responseStatus?: number
  responseBody?: string
  retryTimes: number
  status: 'SUCCESS' | 'FAILURE'
  errorMessage?: string
  createdTime: string
}

export interface WebhookLogQueryDTO extends PageQuery {
  eventType?: string
  status?: string
  startTime?: string
  endTime?: string
}

export function createWebhook(data: WebhookConfigDTO): Promise<Result<number>> {
  return request.post('/api/v1/webhooks', data)
}

export function updateWebhook(id: number, data: WebhookConfigDTO): Promise<Result<void>> {
  return request.put(`/api/v1/webhooks/${id}`, data)
}

export function deleteWebhook(id: number): Promise<Result<void>> {
  return request.delete(`/api/v1/webhooks/${id}`)
}

export function getWebhook(id: number): Promise<Result<WebhookConfigVO>> {
  return request.get(`/api/v1/webhooks/${id}`)
}

export function listWebhooks(params?: WebhookConfigQueryDTO): Promise<Result<PageResult<WebhookConfigVO>>> {
  return request.get('/api/v1/webhooks', { params })
}

export function listWebhookLogs(id: number, params?: WebhookLogQueryDTO): Promise<Result<PageResult<WebhookLogVO>>> {
  return request.get(`/api/v1/webhooks/${id}/logs`, { params })
}
