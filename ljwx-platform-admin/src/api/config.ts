import request from './request'
import type {
  PageResult,
  SysConfigVO,
  ConfigQueryDTO,
  ConfigCreateDTO,
  ConfigUpdateDTO,
} from '@ljwx/shared'

/**
 * 获取配置列表（分页）
 */
export function getConfigList(params?: ConfigQueryDTO): Promise<PageResult<SysConfigVO>> {
  return request.get<PageResult<SysConfigVO>>('/api/configs', { params })
}

/**
 * 创建配置
 */
export function createConfig(data: ConfigCreateDTO): Promise<number> {
  return request.post<number>('/api/configs', data)
}

/**
 * 更新配置
 */
export function updateConfig(id: number, data: ConfigUpdateDTO): Promise<void> {
  return request.put<void>(`/api/configs/${id}`, data)
}

/**
 * 按 key 查询配置
 */
export function getConfigByKey(key: string): Promise<SysConfigVO> {
  return request.get<SysConfigVO>(`/api/configs/key/${key}`)
}
