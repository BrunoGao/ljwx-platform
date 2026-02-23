import type { PageQuery } from './api'

// ============================================================
// Permission 权限类型
// ============================================================

/**
 * 权限视图对象
 */
export interface PermissionVO {
  id: number
  name: string
  /** 权限标识，格式：resource:action，如 user:read */
  code: string
  /** 资源 */
  resource: string
  /** 操作 */
  action: string
}

// ============================================================
// Role 角色类型
// ============================================================

/**
 * 角色视图对象
 */
export interface RoleVO {
  id: number
  name: string
  /** 角色编码 */
  code: string
  description: string
  /** 状态：1-启用 0-禁用 */
  status: number
  createdTime: string
  updatedTime: string
  /** 角色关联的权限列表 */
  permissions: PermissionVO[]
}

/**
 * 角色查询 DTO
 */
export interface RoleQueryDTO extends PageQuery {
  name?: string
  code?: string
  /** 状态：1-启用 0-禁用 */
  status?: number
}

/**
 * 创建角色 DTO（不含 tenantId，由后端自动注入）
 */
export interface RoleCreateDTO {
  name: string
  code: string
  description?: string
  /** 权限 ID 列表 */
  permissionIds?: number[]
}

/**
 * 更新角色 DTO
 */
export interface RoleUpdateDTO {
  name?: string
  code?: string
  description?: string
  /** 状态：1-启用 0-禁用 */
  status?: number
  /** 权限 ID 列表 */
  permissionIds?: number[]
}
