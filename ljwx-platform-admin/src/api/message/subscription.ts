import request from '../request'
import type { PageResult } from '@ljwx/shared'

/**
 * 消息订阅 VO
 */
export interface MsgSubscriptionVO {
  id: number
  userId: number
  userName?: string
  templateId: number
  templateName?: string
  channel: string
  status: string
  preference?: string
  createdTime: string
}

/**
 * 消息订阅查询 DTO
 */
export interface MsgSubscriptionQueryDTO {
  pageNum?: number
  pageSize?: number
  userId?: number
  templateId?: number
  channel?: string
  status?: string
}

/**
 * 消息订阅创建 DTO
 */
export interface MsgSubscriptionCreateDTO {
  userId: number
  templateId: number
  channel: string
  status: string
  preference?: string
}

/**
 * 消息订阅更新 DTO
 */
export interface MsgSubscriptionUpdateDTO {
  userId: number
  templateId: number
  channel: string
  status: string
  preference?: string
}

/**
 * 获取消息订阅列表（分页）
 */
export function getSubscriptionList(params?: MsgSubscriptionQueryDTO): Promise<PageResult<MsgSubscriptionVO>> {
  return request.get<PageResult<MsgSubscriptionVO>>('/api/v1/message/subscriptions', { params })
}

/**
 * 获取消息订阅详情
 */
export function getSubscriptionById(id: number): Promise<MsgSubscriptionVO> {
  return request.get<MsgSubscriptionVO>(`/api/v1/message/subscriptions/${id}`)
}

/**
 * 创建消息订阅
 */
export function createSubscription(data: MsgSubscriptionCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/message/subscriptions', data)
}

/**
 * 更新消息订阅
 */
export function updateSubscription(id: number, data: MsgSubscriptionUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/message/subscriptions/${id}`, data)
}

/**
 * 删除消息订阅
 */
export function deleteSubscription(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/message/subscriptions/${id}`)
}

/**
 * 更新订阅状态
 */
export function updateSubscriptionStatus(id: number, status: string): Promise<void> {
  return request.put<void>(`/api/v1/message/subscriptions/${id}/status`, null, { params: { status } })
}
