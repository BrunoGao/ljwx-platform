import type { PageQuery } from './api'

// ============================================================
// Tenant 租户类型
// ============================================================

export interface TenantVO {
  id: number
  name: string
  code: string
  /** 状态：1-启用 0-禁用 */
  status: number
  createdTime: string
  updatedTime: string
}

export interface TenantQueryDTO extends PageQuery {
  name?: string
  code?: string
  status?: number
}

export interface TenantCreateDTO {
  name: string
  code: string
}

export interface TenantUpdateDTO {
  name?: string
  code?: string
  status?: number
}

// ============================================================
// Dict 字典类型
// ============================================================

/** 字典类型视图对象 */
export interface SysDictTypeVO {
  id: number
  name: string
  type: string
  /** 状态：1-启用 0-禁用 */
  status: number
  remark: string
  createdTime: string
}

/** 字典数据视图对象 */
export interface SysDictDataVO {
  id: number
  dictType: string
  dictLabel: string
  dictValue: string
  sort: number
  /** 状态：1-启用 0-禁用 */
  status: number
  remark: string
}

export interface DictTypeQueryDTO extends PageQuery {
  name?: string
  type?: string
  status?: number
}

export interface DictTypeCreateDTO {
  name: string
  type: string
  remark?: string
}

export interface DictTypeUpdateDTO {
  name?: string
  type?: string
  status?: number
  remark?: string
}

// ============================================================
// Config 系统配置类型
// ============================================================

export interface SysConfigVO {
  id: number
  configKey: string
  configValue: string
  configName: string
  remark: string
  createdTime: string
  updatedTime: string
}

export interface ConfigQueryDTO extends PageQuery {
  configKey?: string
  configName?: string
}

export interface ConfigCreateDTO {
  configKey: string
  configValue: string
  configName: string
  remark?: string
}

export interface ConfigUpdateDTO {
  configKey?: string
  configValue?: string
  configName?: string
  remark?: string
}

// ============================================================
// Job 定时任务类型
// ============================================================

export interface SysJobVO {
  id: number
  jobName: string
  jobGroup: string
  jobClass: string
  cronExpression: string
  /** 状态：1-运行 0-暂停 */
  status: number
  remark: string
  createdTime: string
  updatedTime: string
}

export interface JobQueryDTO extends PageQuery {
  jobName?: string
  jobGroup?: string
  status?: number
}

export interface JobCreateDTO {
  jobName: string
  jobGroup?: string
  jobClass: string
  cronExpression: string
  remark?: string
}

export interface JobUpdateDTO {
  jobName?: string
  jobGroup?: string
  jobClass?: string
  cronExpression?: string
  status?: number
  remark?: string
}

// ============================================================
// Log 日志类型
// ============================================================

/** 操作日志视图对象 */
export interface OperationLogVO {
  id: number
  userId: number
  username: string
  module: string
  operation: string
  method: string
  requestUrl: string
  requestMethod: string
  requestParams: string
  responseResult: string
  ip: string
  /** 耗时（毫秒） */
  duration: number
  /** 状态：1-成功 0-失败 */
  status: number
  errorMessage: string
  createdTime: string
}

export interface OperationLogQueryDTO extends PageQuery {
  username?: string
  module?: string
  status?: number
  startTime?: string
  endTime?: string
}

/** 登录日志视图对象 */
export interface LoginLogVO {
  id: number
  userId: number
  username: string
  ip: string
  userAgent: string
  /** 状态：1-成功 0-失败 */
  status: number
  remark: string
  loginTime: string
}

export interface LoginLogQueryDTO extends PageQuery {
  username?: string
  ip?: string
  status?: number
  startTime?: string
  endTime?: string
}

// ============================================================
// File 文件管理类型
// ============================================================

export interface SysFileVO {
  id: number
  originalName: string
  fileName: string
  filePath: string
  fileUrl: string
  fileSize: number
  mimeType: string
  suffix: string
  createdTime: string
}

export interface FileQueryDTO extends PageQuery {
  originalName?: string
  mimeType?: string
  startTime?: string
  endTime?: string
}

// ============================================================
// Notice 通知公告类型
// ============================================================

export interface SysNoticeVO {
  id: number
  title: string
  content: string
  /** 类型：1-通知 2-公告 */
  type: number
  /** 状态：1-发布 0-草稿 */
  status: number
  createdTime: string
  updatedTime: string
}

export interface NoticeQueryDTO extends PageQuery {
  title?: string
  type?: number
  status?: number
}

export interface NoticeCreateDTO {
  title: string
  content: string
  type: number
}

export interface NoticeUpdateDTO {
  title?: string
  content?: string
  type?: number
  status?: number
}

// ============================================================
// Menu 菜单类型
// ============================================================

export interface MenuVO {
  id: number
  parentId: number
  name: string
  path: string
  component: string
  icon: string
  sort: number
  /** 菜单类型：0=目录 1=菜单 2=按钮 */
  menuType: number
  permission: string
  /** 显示状态：1=显示 0=隐藏 */
  visible: number
  createdTime: string
  updatedTime: string
}

export interface MenuTreeVO extends MenuVO {
  children?: MenuTreeVO[]
}

export interface MenuCreateDTO {
  parentId: number
  name: string
  path?: string
  component?: string
  icon?: string
  sort?: number
  menuType: number
  permission?: string
  visible?: number
}

export interface MenuUpdateDTO {
  parentId?: number
  name?: string
  path?: string
  component?: string
  icon?: string
  sort?: number
  menuType?: number
  permission?: string
  visible?: number
}

// ============================================================
// TenantPackage 租户套餐类型
// ============================================================

export interface TenantPackageVO {
  id: number
  name: string
  /** 关联菜单 ID 列表（逗号分隔） */
  menuIds: string
  maxUsers: number
  maxStorageMb: number
  /** 状态：1-启用 0-停用 */
  status: number
  createdTime: string
  updatedTime: string
}

export interface TenantPackageQueryDTO extends PageQuery {
  name?: string
  status?: number
}

export interface TenantPackageCreateDTO {
  name: string
  menuIds?: string
  maxUsers?: number
  maxStorageMb?: number
}

export interface TenantPackageUpdateDTO {
  name?: string
  menuIds?: string
  maxUsers?: number
  maxStorageMb?: number
  status?: number
}

// ============================================================
// Screen 大屏数据类型
// ============================================================

export interface ScreenOverviewVO {
  /** 用户总数 */
  totalUsers: number
  /** 今日新增用户 */
  todayUsers: number
  /** 租户总数 */
  totalTenants: number
  /** 今日登录次数 */
  todayLoginCount: number
}

export interface ScreenRealtimeVO {
  /** 在线用户数 */
  onlineUsers: number
  /** 实时 QPS */
  qps: number
  /** 系统 CPU 使用率（百分比） */
  cpuUsage: number
  /** 系统内存使用率（百分比） */
  memoryUsage: number
  /** 时间戳 */
  timestamp: string
}

export interface ScreenTrendItem {
  date: string
  value: number
}

export interface ScreenTrendVO {
  /** 用户增长趋势（近 7 天） */
  userTrend: ScreenTrendItem[]
  /** 登录趋势（近 7 天） */
  loginTrend: ScreenTrendItem[]
}
