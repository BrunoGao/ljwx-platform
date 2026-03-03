import request from '../request'

export interface HelpDocVO {
  id: number
  docKey: string
  title: string
  content: string
  category: string
  routeMatch: string | null
  sortOrder: number
  status: number
  createdTime: string
  updatedTime: string
}

export interface HelpDocCreateDTO {
  docKey: string
  title: string
  content: string
  category: string
  routeMatch?: string
  sortOrder?: number
}

export interface HelpDocUpdateDTO {
  title: string
  content: string
  category: string
  routeMatch?: string
  sortOrder?: number
  status: number
}

/**
 * 获取帮助文档列表
 */
export function getHelpDocList(category?: string): Promise<HelpDocVO[]> {
  return request.get<HelpDocVO[]>('/api/v1/help-docs', {
    params: category ? { category } : undefined
  })
}

/**
 * 获取帮助文档详情
 */
export function getHelpDocById(id: number): Promise<HelpDocVO> {
  return request.get<HelpDocVO>(`/api/v1/help-docs/${id}`)
}

/**
 * 按路由匹配获取帮助文档（公开接口）
 */
export function getHelpDocByRoute(path: string): Promise<HelpDocVO | null> {
  return request.get<HelpDocVO | null>('/api/v1/help-docs/route', {
    params: { path }
  })
}

/**
 * 创建帮助文档
 */
export function createHelpDoc(data: HelpDocCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/help-docs', data)
}

/**
 * 更新帮助文档
 */
export function updateHelpDoc(id: number, data: HelpDocUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/help-docs/${id}`, data)
}

/**
 * 删除帮助文档
 */
export function deleteHelpDoc(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/help-docs/${id}`)
}
