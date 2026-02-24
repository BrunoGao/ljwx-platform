import request from './request'
import type { PageResult, SysFileVO, FileQueryDTO } from '@ljwx/shared'

/**
 * 获取文件列表（分页）
 */
export function getFileList(params?: FileQueryDTO): Promise<PageResult<SysFileVO>> {
  return request.get<PageResult<SysFileVO>>('/api/files', { params })
}

/**
 * 上传文件
 */
export function uploadFile(formData: FormData): Promise<SysFileVO> {
  return request.post<SysFileVO>('/api/files/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
}

/**
 * 删除文件
 */
export function deleteFile(id: number): Promise<void> {
  return request.delete<void>(`/api/files/${id}`)
}

/**
 * 获取文件下载 URL
 */
export function getDownloadUrl(id: number): string {
  const base = (import.meta.env.VITE_APP_BASE_API as string | undefined) ?? ''
  return `${base}/api/files/${id}/download`
}
