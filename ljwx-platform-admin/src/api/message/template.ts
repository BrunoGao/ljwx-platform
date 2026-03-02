import request from '../request'
import type { PageResult } from '@ljwx/shared'

/**
 * 消息模板 VO
 */
export interface MsgTemplateVO {
  id: number
  templateCode: string
  templateName: string
  templateType: string
  subject?: string
  content: string
  variables?: string
  status: string
  createdTime: string
  updatedTime: string
}

/**
 * 消息模板查询 DTO
 */
export interface MsgTemplateQueryDTO {
  pageNum?: number
  pageSize?: number
  templateCode?: string
  templateName?: string
  templateType?: string
  status?: string
}

/**
 * 消息模板创建 DTO
 */
export interface MsgTemplateCreateDTO {
  templateCode: string
  templateName: string
  templateType: string
  subject?: string
  content: string
  variables?: string
  status: string
}

/**
 * 消息模板更新 DTO
 */
export interface MsgTemplateUpdateDTO {
  templateCode: string
  templateName: string
  templateType: string
  subject?: string
  content: string
  variables?: string
  status: string
}

/**
 * 获取消息模板列表（分页）
 */
export function getTemplateList(params?: MsgTemplateQueryDTO): Promise<PageResult<MsgTemplateVO>> {
  return request.get<PageResult<MsgTemplateVO>>('/api/v1/messages/templates', { params })
}

/**
 * 获取消息模板详情
 */
export function getTemplateById(id: number): Promise<MsgTemplateVO> {
  return request.get<MsgTemplateVO>(`/api/v1/messages/templates/${id}`)
}

/**
 * 创建消息模板
 */
export function createTemplate(data: MsgTemplateCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/messages/templates', data)
}

/**
 * 更新消息模板
 */
export function updateTemplate(id: number, data: MsgTemplateUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/messages/templates/${id}`, data)
}

/**
 * 删除消息模板
 */
export function deleteTemplate(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/messages/templates/${id}`)
}
