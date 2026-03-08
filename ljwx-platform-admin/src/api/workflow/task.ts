import request from '@/api/request'
import type { PageResult } from '@ljwx/shared'

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

export interface WfTaskQueryDTO {
  status?: string
  pageNum?: number
  pageSize?: number
}

export interface WfTaskActionDTO {
  comment?: string
}

export function getMyTasks(params?: WfTaskQueryDTO): Promise<PageResult<WfTaskVO>> {
  return request.get('/api/v1/workflows/tasks/my', { params })
}

export function approveTask(id: number, data: WfTaskActionDTO): Promise<void> {
  return request.post(`/api/v1/workflows/tasks/${id}/approve`, data)
}

export function rejectTask(id: number, data: WfTaskActionDTO): Promise<void> {
  return request.post(`/api/v1/workflows/tasks/${id}/reject`, data)
}
