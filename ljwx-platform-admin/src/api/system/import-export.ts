import request from '@/api/request'
import type { Result, PageResult } from '@ljwx/shared'

export interface ImportExportTaskVO {
  id: number
  taskType: 'IMPORT' | 'EXPORT'
  businessType: string
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
  businessType?: string
  status?: 'PENDING' | 'PROCESSING' | 'SUCCESS' | 'FAILURE'
  pageNum?: number
  pageSize?: number
}

export interface ImportTaskDTO {
  taskType: 'IMPORT'
  businessType: string
  fileName: string
  file: File
}

export interface ExportTaskDTO {
  taskType: 'EXPORT'
  businessType: string
  fileName: string
}

export function importData(data: FormData): Promise<Result<number>> {
  return request.post('/api/v1/import-export/import', data, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

export function exportData(data: ExportTaskDTO): Promise<Result<number>> {
  return request.post('/api/v1/import-export/export', data)
}

export function getTask(id: number): Promise<Result<ImportExportTaskVO>> {
  return request.get(`/api/v1/import-export/tasks/${id}`)
}

export function listTasks(params?: ImportExportTaskQueryDTO): Promise<Result<PageResult<ImportExportTaskVO>>> {
  return request.get('/api/v1/import-export/tasks', { params })
}
