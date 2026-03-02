import request from '@/api/request'
import type { Result, PageResult } from '@ljwx/shared'

export interface ImportExportTaskVO {
  id: number
  taskType: 'IMPORT' | 'EXPORT'
  businessType: 'USER' | 'ROLE' | 'DEPT' | 'MENU'
  fileName: string
  fileUrl?: string
  status: 'PENDING' | 'PROCESSING' | 'SUCCESS' | 'FAILURE'
  totalCount: number
  successCount: number
  failureCount: number
  errorMessage?: string
  createdTime: string
}

export interface ImportExportTaskQueryDTO {
  taskType?: 'IMPORT' | 'EXPORT'
  businessType?: 'USER' | 'ROLE' | 'DEPT' | 'MENU'
  status?: 'PENDING' | 'PROCESSING' | 'SUCCESS' | 'FAILURE'
  pageNum?: number
  pageSize?: number
}

export interface ImportRequestDTO {
  taskType: 'IMPORT'
  businessType: 'USER' | 'ROLE' | 'DEPT' | 'MENU'
  fileName: string
  file: File
}

export interface ExportRequestDTO {
  taskType: 'EXPORT'
  businessType: 'USER' | 'ROLE' | 'DEPT' | 'MENU'
  fileName: string
}

/**
 * 导入数据
 */
export function importData(formData: FormData): Promise<Result<number>> {
  return request.post('/api/v1/import-export/import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

/**
 * 导出数据
 */
export function exportData(data: ExportRequestDTO): Promise<Result<number>> {
  return request.post('/api/v1/import-export/export', data)
}

export function getTask(id: number): Promise<Result<ImportExportTaskVO>> {
  return request.get(`/api/v1/import-export/tasks/${id}`)
}

export function listTasks(params?: ImportExportTaskQueryDTO): Promise<Result<PageResult<ImportExportTaskVO>>> {
  return request.get('/api/v1/import-export/tasks', { params })
}
