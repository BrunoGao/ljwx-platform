import request from '@/api/request'
import type { PageResult } from '@ljwx/shared'

export interface WfDefinitionVO {
  id: number
  flowKey: string
  flowName: string
  flowVersion: number
  flowConfig: string
  status: string
  createdTime: string
  updatedTime: string
}

export interface WfDefinitionDTO {
  flowKey: string
  flowName: string
  flowConfig: string
}

export interface WfDefinitionQueryDTO {
  flowKey?: string
  flowName?: string
  status?: string
  pageNum?: number
  pageSize?: number
}

export function getDefinitionList(params?: WfDefinitionQueryDTO): Promise<PageResult<WfDefinitionVO>> {
  return request.get('/api/v1/workflows/definitions', { params })
}

export function createDefinition(data: WfDefinitionDTO): Promise<number> {
  return request.post('/api/v1/workflows/definitions', data)
}

export function updateDefinition(id: number, data: WfDefinitionDTO): Promise<void> {
  return request.put(`/api/v1/workflows/definitions/${id}`, data)
}

export function deleteDefinition(id: number): Promise<void> {
  return request.delete(`/api/v1/workflows/definitions/${id}`)
}
