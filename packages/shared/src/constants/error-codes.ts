/**
 * 业务错误码常量（与后端 ErrorCode 枚举对应）
 * 对应 spec/03-api.md §错误码
 */
export const ErrorCodes = {
  /** 成功 */
  SUCCESS: 200,
  /** 参数校验失败 */
  PARAM_INVALID: 400001,
  /** Token 无效 */
  TOKEN_INVALID: 401001,
  /** Token 过期 */
  TOKEN_EXPIRED: 401002,
  /** 租户拒绝 */
  TENANT_REJECTED: 403001,
  /** 权限不足 */
  FORBIDDEN: 403002,
  /** 资源不存在 */
  NOT_FOUND: 404001,
  /** 系统内部错误 */
  INTERNAL_ERROR: 500001,
} as const

/** 错误码类型，等同于 ErrorCodes 各值的联合类型 */
export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes]

/** 错误码对应的中文描述映射 */
export const ErrorMessages: Record<ErrorCode, string> = {
  [ErrorCodes.SUCCESS]: '成功',
  [ErrorCodes.PARAM_INVALID]: '参数校验失败',
  [ErrorCodes.TOKEN_INVALID]: 'Token 无效',
  [ErrorCodes.TOKEN_EXPIRED]: 'Token 已过期',
  [ErrorCodes.TENANT_REJECTED]: '租户访问被拒绝',
  [ErrorCodes.FORBIDDEN]: '权限不足',
  [ErrorCodes.NOT_FOUND]: '资源不存在',
  [ErrorCodes.INTERNAL_ERROR]: '系统内部错误',
}
