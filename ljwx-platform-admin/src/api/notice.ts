import request from './request'
import type {
  PageResult,
  SysNoticeVO,
  NoticeQueryDTO,
  NoticeCreateDTO,
  NoticeUpdateDTO,
} from '@ljwx/shared'

/**
 * 获取通知列表（分页）
 */
export function getNoticeList(params?: NoticeQueryDTO): Promise<PageResult<SysNoticeVO>> {
  return request.get<PageResult<SysNoticeVO>>('/api/notices', { params })
}

/**
 * 创建通知
 */
export function createNotice(data: NoticeCreateDTO): Promise<number> {
  return request.post<number>('/api/notices', data)
}

/**
 * 更新通知
 */
export function updateNotice(id: number, data: NoticeUpdateDTO): Promise<void> {
  return request.put<void>(`/api/notices/${id}`, data)
}
