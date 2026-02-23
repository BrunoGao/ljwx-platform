/**
 * RBAC 权限常量（与后端 sys_permission 种子数据对应）
 * 对应 spec/01-constraints.md §RBAC 权限
 *
 * 格式：resource:action
 */
export const Permissions = {
  // ── 用户管理 ──
  USER_READ: 'user:read',
  USER_WRITE: 'user:write',
  USER_DELETE: 'user:delete',

  // ── 角色管理 ──
  ROLE_READ: 'role:read',
  ROLE_WRITE: 'role:write',
  ROLE_DELETE: 'role:delete',

  // ── 租户管理 ──
  TENANT_READ: 'tenant:read',
  TENANT_WRITE: 'tenant:write',

  // ── 定时任务 ──
  JOB_READ: 'job:read',
  JOB_WRITE: 'job:write',
  JOB_EXECUTE: 'job:execute',

  // ── 字典管理 ──
  DICT_READ: 'dict:read',
  DICT_WRITE: 'dict:write',

  // ── 系统配置 ──
  CONFIG_READ: 'config:read',
  CONFIG_WRITE: 'config:write',

  // ── 日志管理 ──
  LOG_READ: 'log:read',
  LOG_EXPORT: 'log:export',

  // ── 文件管理 ──
  FILE_READ: 'file:read',
  FILE_UPLOAD: 'file:upload',
  FILE_DELETE: 'file:delete',

  // ── 通知公告 ──
  NOTICE_READ: 'notice:read',
  NOTICE_WRITE: 'notice:write',

  // ── 数据大屏 ──
  SCREEN_READ: 'screen:read',
} as const

/** 权限字符串字面量联合类型 */
export type Permission = (typeof Permissions)[keyof typeof Permissions]

/** 所有权限字符串数组（用于 admin 角色种子数据） */
export const ALL_PERMISSIONS: Permission[] = Object.values(Permissions)
