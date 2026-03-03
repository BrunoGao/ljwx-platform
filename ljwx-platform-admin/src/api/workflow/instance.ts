import request from '@/api/request'
import type { Result, PageResult } from '@ljwx/shared'

export interface WfInstanceVO {
  id: number
  definitionId: number
  businessKey: string
  businessType: string
  initiatorId: number
  currentNode: string
  status: string
  startTime: string
  endTime?: string
  createdTime: string
  updatedTime: string
}

export interface WfInstanceDTO {
  definitionId: number
  businessKey: string
  businessType: string
}

export interface WfInstanceQueryDTO {
  businessKey?: string
  businessType?: string
  status?: string
  pageNum?: number
  pageSize?: number
}

export function getInstanceList(params?: WfInstanceQueryDTO): Promise<Result<PageResult<WfInstanceVO>>> {
  return request.get('/api/v1/workflows/instances', { params })
}

export function getInstance(id: number): Promise<Result<WfInstanceVO>> {
  return request.get(`/api/v1/workflows/instances/${id}`)
}

export function startInstance(data: WfInstanceDTO): Promise<Result<number>> {
  return request.post('/api/v1/workflows/instances', data)
}
