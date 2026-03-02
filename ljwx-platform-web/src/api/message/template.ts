import request from '@/api/request'
import type { Result, PageResult } from '@ljwx/shared'

export interface MsgTemplateVO {
  id: number
  templateCode: string
  templateName: string
  templateType: string
  subject: string
  content: string
  variables: string
  status: string
  createdTime: string
  updatedTime: string
}

export interface MsgTemplateDTO {
  templateCode: string
  templateName: string
  templateType: string
  subject?: string
  content: string
  variables?: string
  status: string
}

export interface MsgTemplateQueryDTO {
  templateCode?: string
  templateName?: string
  templateType?: string
  status?: string
  pageNum?: number
  pageSize?: number
}

export function createTemplate(data: MsgTemplateDTO): Promise<Result<number>> {
  return request.post('/api/v1/messages/templates', data)
}

export function updateTemplate(id: number, data: MsgTemplateDTO): Promise<Result<void>> {
  return request.put(`/api/v1/messages/templates/${id}`, data)
}

export function deleteTemplate(id: number): Promise<Result<void>> {
  return request.delete(`/api/v1/messages/templates/${id}`)
}

export function getTemplate(id: number): Promise<Result<MsgTemplateVO>> {
  return request.get(`/api/v1/messages/templates/${id}`)
}

export function listTemplates(params?: MsgTemplateQueryDTO): Promise<Result<PageResult<MsgTemplateVO>>> {
  return request.get('/api/v1/messages/templates', { params })
}
