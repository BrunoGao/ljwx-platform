import request from './request'
import type {
  PageResult,
  TaskExecutionLogVO,
  TaskExecutionLogQueryDTO,
  TaskLogStatsVO,
} from '@ljwx/shared'

/**
 * 获取任务执行日志列表（分页）
 */
export function getTaskLogList(
  params?: TaskExecutionLogQueryDTO,
): Promise<PageResult<TaskExecutionLogVO>> {
  return request.get<PageResult<TaskExecutionLogVO>>('/api/v1/task-logs', { params })
}

/**
 * 获取任务执行日志详情
 */
export function getTaskLogDetail(id: number): Promise<TaskExecutionLogVO> {
  return request.get<TaskExecutionLogVO>(`/api/v1/task-logs/${id}`)
}

/**
 * 删除任务执行日志
 */
export function deleteTaskLog(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/task-logs/${id}`)
}

/**
 * 清理历史日志（30 天前）
 */
export function cleanOldTaskLogs(): Promise<number> {
  return request.post<number>('/api/v1/task-logs/clean')
}

/**
 * 获取任务执行统计
 */
export function getTaskLogStats(): Promise<TaskLogStatsVO> {
  return request.get<TaskLogStatsVO>('/api/v1/task-logs/stats')
}
