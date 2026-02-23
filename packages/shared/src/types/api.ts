/**
 * 统一响应结构（与后端 Result<T> 对应）
 */
export interface Result<T = unknown> {
  /** 业务状态码，200 表示成功 */
  code: number
  /** 响应信息 */
  message: string
  /** 响应数据 */
  data: T
  /** 链路追踪 ID */
  traceId: string
}

/**
 * 分页结果（与后端 PageResult<T> 对应）
 */
export interface PageResult<T = unknown> {
  /** 数据列表 */
  rows: T[]
  /** 总条数 */
  total: number
}

/**
 * 分页查询通用参数
 */
export interface PageQuery {
  /** 当前页码，从 1 开始 */
  pageNum?: number
  /** 每页条数，默认 10 */
  pageSize?: number
}
