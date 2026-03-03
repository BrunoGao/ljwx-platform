import request from '@/api/request'
import type { Result } from '@ljwx/shared'

export interface CustomFieldDefVO {
  id: number
  entityType: string
  fieldKey: string
  fieldLabel: string
  fieldType: string
  required: boolean
  sortOrder: number
  options?: unknown[]
  createdTime: string
}

export interface CustomFieldDefCreateDTO {
  entityType: string
  fieldKey: string
  fieldLabel: string
  fieldType: string
  required: boolean
  sortOrder: number
  options?: unknown[]
}

export interface CustomFieldDefUpdateDTO {
  fieldLabel: string
  required: boolean
  sortOrder: number
  options?: unknown[]
}

export function getCustomFieldList(entityType?: string): Promise<Result<CustomFieldDefVO[]>> {
  return request.get('/api/v1/custom-fields', { params: { entityType } })
}

export function createCustomField(data: CustomFieldDefCreateDTO): Promise<Result<number>> {
  return request.post('/api/v1/custom-fields', data)
}

export function updateCustomField(id: number, data: CustomFieldDefUpdateDTO): Promise<Result<void>> {
  return request.put(`/api/v1/custom-fields/${id}`, data)
}

export function deleteCustomField(id: number): Promise<Result<void>> {
  return request.delete(`/api/v1/custom-fields/${id}`)
}
