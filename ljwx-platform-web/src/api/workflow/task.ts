import request from '@/api/request'
import type { Result, PageResult } from '@ljwx/shared'

export interface WfTaskVO {
  id: number
  instanceId: number
  taskName: string
  taskType: string
  assigneeId: number
  status: string
  comment?: string
  handleTime?: string
  createdTime: string
  updatedTime: string
}

export interface WfTaskActionDTO {
  comment?: string
}

export interface WfTaskQueryDTO {
  status?: string
  pageNum?: number
  pageSize?: number
}

export function getMyTasks(params?: WfTaskQueryDTO): Promise<Result<PageResult<WfTaskVO>>> {
  return request.get('/api/v1/workflows/tasks/my', { params })
}

export function approveTask(id: number, data: WfTaskActionDTO): Promise<Result<void>> {
  return request.post(`/api/v1/workflows/tasks/${id}/approve`, data)
}

export function rejectTask(id: number, data: WfTaskActionDTO): Promise<Result<void>> {
  return request.post(`/api/v1/workflows/tasks/${id}/reject`, data)
}
