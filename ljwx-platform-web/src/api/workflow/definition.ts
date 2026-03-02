import request from '@/api/request'
import type { Result, PageResult } from '@ljwx/shared'

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
  status: string
}

export interface WfDefinitionQueryDTO {
  flowKey?: string
  flowName?: string
  status?: string
  pageNum?: number
  pageSize?: number
}

export function createDefinition(data: WfDefinitionDTO): Promise<Result<number>> {
  return request.post('/api/v1/workflows/definitions', data)
}

export function updateDefinition(id: number, data: WfDefinitionDTO): Promise<Result<void>> {
  return request.put(`/api/v1/workflows/definitions/${id}`, data)
}

export function deleteDefinition(id: number): Promise<Result<void>> {
  return request.delete(`/api/v1/workflows/definitions/${id}`)
}

export function getDefinition(id: number): Promise<Result<WfDefinitionVO>> {
  return request.get(`/api/v1/workflows/definitions/${id}`)
}

export function listDefinitions(params?: WfDefinitionQueryDTO): Promise<Result<PageResult<WfDefinitionVO>>> {
  return request.get('/api/v1/workflows/definitions', { params })
}
