import request from '@/api/request'
import type { Result, PageResult } from '@ljwx/shared'

export interface MsgSubscriptionVO {
  id: number
  userId: number
  userName: string
  templateId: number
  templateName: string
  channel: string
  status: string
  preference: string
  createdTime: string
}

export interface MsgSubscriptionDTO {
  userId: number
  templateId: number
  channel: string
  status: string
  preference?: string
}

export interface MsgSubscriptionQueryDTO {
  userId?: number
  templateId?: number
  channel?: string
  status?: string
  pageNum?: number
  pageSize?: number
}

export function createSubscription(data: MsgSubscriptionDTO): Promise<Result<number>> {
  return request.post('/api/v1/message/subscriptions', data)
}

export function updateSubscription(id: number, data: MsgSubscriptionDTO): Promise<Result<void>> {
  return request.put(`/api/v1/message/subscriptions/${id}`, data)
}

export function deleteSubscription(id: number): Promise<Result<void>> {
  return request.delete(`/api/v1/message/subscriptions/${id}`)
}

export function getSubscription(id: number): Promise<Result<MsgSubscriptionVO>> {
  return request.get(`/api/v1/message/subscriptions/${id}`)
}

export function listSubscriptions(params?: MsgSubscriptionQueryDTO): Promise<Result<PageResult<MsgSubscriptionVO>>> {
  return request.get('/api/v1/message/subscriptions', { params })
}

export function updateSubscriptionStatus(id: number, status: string): Promise<Result<void>> {
  return request.put(`/api/v1/message/subscriptions/${id}/status`, null, { params: { status } })
}
