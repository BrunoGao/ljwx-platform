import request from '@/api/request'
import type { PageResult } from '@ljwx/shared'

/**
 * 数据变更日志视图对象
 */
export interface DataChangeLogVO {
  id: number
  tableName: string
  recordId: number
  fieldName: string
  oldValue: string
  newValue: string
  operateType: string
  createdBy: string
  createdTime: string
}

/**
 * 数据变更日志查询参数
 */
export interface DataChangeLogQuery {
  tableName?: string
  recordId?: number
  startTime?: string
  endTime?: string
  pageNum: number
  pageSize: number
}

/**
 * 获取数据变更日志列表
 */
export function getDataChangeLogs(params: DataChangeLogQuery): Promise<PageResult<DataChangeLogVO>> {
  return request.get('/data-change-logs', { params })
}
