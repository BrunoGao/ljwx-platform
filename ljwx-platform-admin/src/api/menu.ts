import request from './request'
import type { MenuVO, MenuTreeVO, MenuCreateDTO, MenuUpdateDTO } from '@ljwx/shared'

export function getMenuList(): Promise<MenuVO[]> {
  return request.get<MenuVO[]>('/api/v1/menus')
}

export function getMenuTree(): Promise<MenuTreeVO[]> {
  return request.get<MenuTreeVO[]>('/api/v1/menus/tree')
}

export function getMenuDetail(id: number): Promise<MenuVO> {
  return request.get<MenuVO>(`/api/v1/menus/${id}`)
}

export function createMenu(data: MenuCreateDTO): Promise<number> {
  return request.post<number>('/api/v1/menus', data)
}

export function updateMenu(id: number, data: MenuUpdateDTO): Promise<void> {
  return request.put<void>(`/api/v1/menus/${id}`, data)
}

export function deleteMenu(id: number): Promise<void> {
  return request.delete<void>(`/api/v1/menus/${id}`)
}
