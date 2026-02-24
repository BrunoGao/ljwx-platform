import request from './request'
import type {
  PageResult,
  SysDictTypeVO,
  SysDictDataVO,
  DictTypeQueryDTO,
  DictTypeCreateDTO,
  DictTypeUpdateDTO,
} from '@ljwx/shared'

/**
 * 获取字典类型列表（分页）
 */
export function getDictList(params?: DictTypeQueryDTO): Promise<PageResult<SysDictTypeVO>> {
  return request.get<PageResult<SysDictTypeVO>>('/api/dicts', { params })
}

/**
 * 创建字典类型
 */
export function createDict(data: DictTypeCreateDTO): Promise<number> {
  return request.post<number>('/api/dicts', data)
}

/**
 * 更新字典类型
 */
export function updateDict(id: number, data: DictTypeUpdateDTO): Promise<void> {
  return request.put<void>(`/api/dicts/${id}`, data)
}

/**
 * 按类型查询字典数据列表
 */
export function getDictDataByType(type: string): Promise<SysDictDataVO[]> {
  return request.get<SysDictDataVO[]>(`/api/dicts/type/${type}`)
}
