import request from './request'
import type {
  PageResult,
  SysJobVO,
  JobQueryDTO,
  JobCreateDTO,
  JobUpdateDTO,
} from '@ljwx/shared'

/**
 * 获取定时任务列表（分页）
 */
export function getJobList(params?: JobQueryDTO): Promise<PageResult<SysJobVO>> {
  return request.get<PageResult<SysJobVO>>('/api/v1/jobs', { params })
}

/**
 * 创建定时任务
 */
export function createJob(data: JobCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/jobs', data)
}

/**
 * 更新定时任务
 */
export function updateJob(id: number, data: JobUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/jobs/${id}`, data)
}

/**
 * 立即执行任务
 */
export function executeJob(id: number): Promise<void> {
  return request.post<void>(`/api/v1/jobs/${id}/run`)
}

/**
 * 暂停任务
 */
export function pauseJob(id: number): Promise<void> {
  return request.post<void>(`/api/v1/jobs/${id}/pause`)
}

/**
 * 恢复任务
 */
export function resumeJob(id: number): Promise<void> {
  return request.post<void>(`/api/v1/jobs/${id}/resume`)
}
