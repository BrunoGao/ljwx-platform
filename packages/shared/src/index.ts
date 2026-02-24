/**
 * @ljwx/shared — LJWX Platform 前端共享包
 *
 * 包含：
 * - types: API 类型定义（Result, PageResult, 各模块 VO/DTO）
 * - constants: 错误码、RBAC 权限常量
 * - utils: 工具函数（脱敏、格式化、权限判断）
 */

// ── Types ──
export type { Result, PageResult, PageQuery } from './types/api'
export type {
  LoginDTO,
  TokenVO,
  UserInfo,
  LoginVO,
  UserVO,
  UserRoleVO,
  UserQueryDTO,
  UserCreateDTO,
  UserUpdateDTO,
} from './types/user'
export type {
  PermissionVO,
  RoleVO,
  RoleQueryDTO,
  RoleCreateDTO,
  RoleUpdateDTO,
} from './types/role'
export type {
  TenantVO,
  TenantQueryDTO,
  TenantCreateDTO,
  TenantUpdateDTO,
  SysDictTypeVO,
  SysDictDataVO,
  DictTypeQueryDTO,
  DictTypeCreateDTO,
  DictTypeUpdateDTO,
  SysConfigVO,
  ConfigQueryDTO,
  ConfigCreateDTO,
  ConfigUpdateDTO,
  SysJobVO,
  JobQueryDTO,
  JobCreateDTO,
  JobUpdateDTO,
  OperationLogVO,
  OperationLogQueryDTO,
  LoginLogVO,
  LoginLogQueryDTO,
  SysFileVO,
  FileQueryDTO,
  SysNoticeVO,
  NoticeQueryDTO,
  NoticeCreateDTO,
  NoticeUpdateDTO,
  ScreenOverviewVO,
  ScreenRealtimeVO,
  ScreenTrendItem,
  ScreenTrendVO,
  MenuVO,
  MenuTreeVO,
  MenuCreateDTO,
  MenuUpdateDTO,
  TenantPackageVO,
  TenantPackageQueryDTO,
  TenantPackageCreateDTO,
  TenantPackageUpdateDTO,
} from './types/common'

// ── Constants ──
export {
  ErrorCodes,
  ErrorMessages,
} from './constants/error-codes'
export type { ErrorCode } from './constants/error-codes'

export {
  Permissions,
  ALL_PERMISSIONS,
} from './constants/permissions'
export type { Permission } from './constants/permissions'

// ── Utils ──
export {
  maskPassword,
  maskPhone,
  maskIdCard,
  formatDate,
  formatFileSize,
  hasPermission,
  hasAnyPermission,
  hasAllPermissions,
} from './utils/index'
