import request from './request'
import type {
  PageResult,
  OperationLogVO,
  OperationLogQueryDTO,
  LoginLogVO,
  LoginLogQueryDTO,
} from '@ljwx/shared'

/**
 * 获取操作日志列表（分页）
 */
export function getOperationLogList(
  params?: OperationLogQueryDTO,
): Promise<PageResult<OperationLogVO>> {
  return request.get<PageResult<OperationLogVO>>('/api/v1/logs/operation', { params })
}

/**
 * 获取登录日志列表（分页）
 */
export function getLoginLogList(params?: LoginLogQueryDTO): Promise<PageResult<LoginLogVO>> {
  return request.get<PageResult<LoginLogVO>>('/api/v1/logs/login', { params })
}

/**
 * 导出日志
 */
export function exportLogs(): Promise<Blob> {
  return request.post<Blob>('/api/v1/logs/export', undefined, { responseType: 'blob' })
}
