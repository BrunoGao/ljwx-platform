import request from './request'
import type { PageResult } from '@ljwx/shared'

export interface DeptVO {
  id: number
  parentId: number
  name: string
  leader: string
  phone: string
  email: string
  sort: number
  /** 状态：1-启用 0-禁用 */
  status: number
  remark: string
  createdTime: string
  updatedTime: string
}

export interface DeptTreeVO extends DeptVO {
  children?: DeptTreeVO[]
}

export interface DeptQueryDTO {
  name?: string
  status?: number
  pageNum?: number
  pageSize?: number
}

export interface DeptCreateDTO {
  parentId: number
  name: string
  sort?: number
  leader?: string
  phone?: string
  email?: string
  status?: number
  remark?: string
}

export interface DeptUpdateDTO {
  parentId?: number
  name?: string
  sort?: number
  leader?: string
  phone?: string
  email?: string
  status?: number
  remark?: string
}

export function getDeptList(params?: DeptQueryDTO): Promise<PageResult<DeptVO>> {
  return request.get<PageResult<DeptVO>>('/api/v1/depts', { params })
}

export function getDeptTree(): Promise<DeptTreeVO[]> {
  return request.get<DeptTreeVO[]>('/api/v1/depts/tree')
}

export function getDeptDetail(id: number): Promise<DeptVO> {
  return request.get<DeptVO>(`/api/v1/depts/${id}`)
}

export function createDept(data: DeptCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/depts', data)
}

export function updateDept(id: number, data: DeptUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/depts/${id}`, data)
}

export function deleteDept(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/depts/${id}`)
}
