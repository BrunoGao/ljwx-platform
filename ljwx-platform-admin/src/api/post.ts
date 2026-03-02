import request from './request'
import type { PageResult } from '@ljwx/shared'

export interface PostVO {
  id: number
  postCode: string
  postName: string
  postSort: number
  status: string
  remark: string
  createdTime: string
  updatedTime: string
}

export interface PostQueryDTO {
  postCode?: string
  postName?: string
  status?: string
  pageNum?: number
  pageSize?: number
}

export interface PostCreateDTO {
  postCode: string
  postName: string
  postSort: number
  status: string
  remark?: string
}

export interface PostUpdateDTO {
  postCode?: string
  postName?: string
  postSort?: number
  status?: string
  remark?: string
}

export function getPostList(params?: PostQueryDTO): Promise<PageResult<PostVO>> {
  return request.get<PageResult<PostVO>>('/api/v1/posts', { params })
}

export function getPostDetail(id: number): Promise<PostVO> {
  return request.get<PostVO>(`/api/v1/posts/${id}`)
}

export function createPost(data: PostCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/posts', data)
}

export function updatePost(id: number, data: PostUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/posts/${id}`, data)
}

export function deletePost(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/posts/${id}`)
}
