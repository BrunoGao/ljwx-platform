import request from './request'
import type { Result, PageResult, SysNoticeVO, NoticeQueryDTO } from '@ljwx/shared'

export function getNoticeList(params?: NoticeQueryDTO): Promise<Result<PageResult<SysNoticeVO>>> {
  return request.get('/api/v1/notices', { params })
}

export function getNoticeDetail(id: number): Promise<Result<SysNoticeVO>> {
  return request.get(`/api/v1/notices/${id}`)
}
