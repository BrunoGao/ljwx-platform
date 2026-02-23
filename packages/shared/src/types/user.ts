import type { PageQuery } from './api'

// ============================================================
// Auth 认证相关类型
// ============================================================

/**
 * 登录请求 DTO
 */
export interface LoginDTO {
  username: string
  password: string
}

/**
 * Token 信息
 */
export interface TokenVO {
  accessToken: string
  refreshToken: string
  /** Access Token 过期时间（秒） */
  expiresIn: number
}

/**
 * 当前登录用户信息
 */
export interface UserInfo {
  id: number
  username: string
  nickname: string
  email: string
  phone: string
  avatar: string
  /** 权限字符串数组，如 ["user:read", "user:write"] */
  authorities: string[]
  /** 角色 code 数组 */
  roles: string[]
  tenantId: number
}

/**
 * 登录响应（Token + 用户信息）
 */
export interface LoginVO extends TokenVO {
  userInfo: UserInfo
}

// ============================================================
// User 用户管理类型
// ============================================================

/**
 * 用户视图对象
 */
export interface UserVO {
  id: number
  username: string
  nickname: string
  email: string
  phone: string
  avatar: string
  /** 状态：1-启用 0-禁用 */
  status: number
  createdTime: string
  updatedTime: string
  /** 用户关联的角色列表 */
  roles: UserRoleVO[]
}

/**
 * 用户角色简要信息（用于 UserVO 中的 roles 字段）
 */
export interface UserRoleVO {
  id: number
  name: string
  code: string
}

/**
 * 用户查询 DTO
 */
export interface UserQueryDTO extends PageQuery {
  username?: string
  nickname?: string
  /** 状态：1-启用 0-禁用 */
  status?: number
}

/**
 * 创建用户 DTO（不含 tenantId，由后端自动注入）
 */
export interface UserCreateDTO {
  username: string
  password: string
  nickname: string
  email?: string
  phone?: string
  /** 角色 ID 列表 */
  roleIds?: number[]
}

/**
 * 更新用户 DTO
 */
export interface UserUpdateDTO {
  nickname?: string
  email?: string
  phone?: string
  /** 状态：1-启用 0-禁用 */
  status?: number
  /** 角色 ID 列表 */
  roleIds?: number[]
}
