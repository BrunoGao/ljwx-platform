import request from '@/api/request'
import type { PageResult } from '@ljwx/shared'

export interface FormDefVO {
  id: number
  formName: string
  formKey: string
  schema: Record<string, unknown>
  status: number
  remark?: string
  createdTime: string
  updatedTime: string
}

export interface FormDefQueryDTO {
  formName?: string
  formKey?: string
  status?: number
  pageNum: number
  pageSize: number
}

export interface FormDefCreateDTO {
  formName: string
  formKey: string
  schema: Record<string, unknown>
  remark?: string
}

export interface FormDefUpdateDTO {
  formName: string
  schema: Record<string, unknown>
  status: number
  remark?: string
}

export function getFormDefList(params: FormDefQueryDTO): Promise<PageResult<FormDefVO>> {
  return request.get('/api/v1/form-defs', { params })
}

export function getFormDefById(id: number): Promise<FormDefVO> {
  return request.get(`/api/v1/form-defs/${id}`)
}

export function createFormDef(data: FormDefCreateDTO): Promise<number> {
  return request.post('/api/v1/form-defs', data)
}

export function updateFormDef(id: number, data: FormDefUpdateDTO): Promise<void> {
  return request.put(`/api/v1/form-defs/${id}`, data)
}

export function deleteFormDef(id: number): Promise<void> {
  return request.delete(`/api/v1/form-defs/${id}`)
}
