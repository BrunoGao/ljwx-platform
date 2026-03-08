import request from '@/api/request'
import type { PageResult } from '@ljwx/shared'

export interface FormDataVO {
  id: number
  formDefId: number
  fieldValues: Record<string, unknown>
  creatorId: number
  createdTime: string
  updatedTime: string
}

export interface FormDataQueryDTO {
  formDefId: number
  creatorId?: number
  startTime?: string
  endTime?: string
  pageNum: number
  pageSize: number
}

export interface FormDataCreateDTO {
  formDefId: number
  fieldValues: Record<string, unknown>
}

export interface FormDataUpdateDTO {
  fieldValues: Record<string, unknown>
}

export function getFormDataList(params: FormDataQueryDTO): Promise<PageResult<FormDataVO>> {
  return request.get('/api/v1/form-data', { params })
}

export function getFormDataById(id: number): Promise<FormDataVO> {
  return request.get(`/api/v1/form-data/${id}`)
}

export function createFormData(data: FormDataCreateDTO): Promise<number> {
  return request.post('/api/v1/form-data', data)
}

export function updateFormData(id: number, data: FormDataUpdateDTO): Promise<void> {
  return request.put(`/api/v1/form-data/${id}`, data)
}
