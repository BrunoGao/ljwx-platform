import request from './request'
import type { PageResult, LoginLogVO, LoginLogQueryDTO } from '@ljwx/shared'

export function getLoginLogList(params?: LoginLogQueryDTO): Promise<PageResult<LoginLogVO>> {
  return request.get<PageResult<LoginLogVO>>('/api/v1/login-logs', { params })
}
