import request from '../request'
import type { PageResult } from '@ljwx/shared'

/**
 * 报表定义 VO
 */
export interface ReportDefVO {
  id: number
  reportName: string
  reportKey: string
  dataSourceType: string
  queryTemplate: string
  columnDef: ColumnDefItem[]
  filterDef: FilterDefItem[]
  status: number
  remark: string
  createdTime: string
  updatedTime: string
}

/**
 * 列定义
 */
export interface ColumnDefItem {
  name: string
  title: string
  type: string
  width?: number
  format?: string
}

/**
 * 过滤器定义
 */
export interface FilterDefItem {
  paramName: string
  paramType: string
  label: string
  required: boolean
  defaultValue?: string
}

/**
 * 报表定义查询 DTO
 */
export interface ReportDefQueryDTO {
  pageNum?: number
  pageSize?: number
  reportName?: string
  reportKey?: string
  status?: number
}

/**
 * 报表定义创建 DTO
 */
export interface ReportDefCreateDTO {
  reportName: string
  reportKey: string
  dataSourceType: string
  queryTemplate: string
  columnDef: ColumnDefItem[]
  filterDef?: FilterDefItem[]
  remark?: string
}

/**
 * 报表定义更新 DTO
 */
export interface ReportDefUpdateDTO {
  reportName: string
  dataSourceType: string
  queryTemplate: string
  columnDef: ColumnDefItem[]
  filterDef?: FilterDefItem[]
  status: number
  remark?: string
}

/**
 * 报表执行 DTO
 */
export interface ReportExecuteDTO {
  params?: Record<string, unknown>
  pageNum?: number
  pageSize?: number
}

/**
 * 列元数据
 */
export interface ColumnMeta {
  name: string
  title: string
  type: string
}

/**
 * 报表执行结果 VO
 */
export interface ReportResultVO {
  columns: ColumnMeta[]
  rows: Record<string, unknown>[]
  total: number
  pageNum: number
  pageSize: number
  warnings: string[]
}

/**
 * 获取报表定义列表（分页）
 */
export function getReportDefList(params?: ReportDefQueryDTO): Promise<PageResult<ReportDefVO>> {
  return request.get<PageResult<ReportDefVO>>('/api/v1/reports', { params })
}

/**
 * 获取报表定义详情
 */
export function getReportDefById(id: number): Promise<ReportDefVO> {
  return request.get<ReportDefVO>(`/api/v1/reports/${id}`)
}

/**
 * 创建报表定义
 */
export function createReportDef(data: ReportDefCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/reports', data)
}

/**
 * 更新报表定义
 */
export function updateReportDef(id: number, data: ReportDefUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/reports/${id}`, data)
}

/**
 * 删除报表定义
 */
export function deleteReportDef(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/reports/${id}`)
}

/**
 * 执行报表查询
 */
export function executeReport(id: number, data: ReportExecuteDTO): Promise<ReportResultVO> {
  return request.post<ReportResultVO>(`/api/v1/reports/${id}/execute`, data)
}
