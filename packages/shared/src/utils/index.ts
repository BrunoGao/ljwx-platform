/**
 * 敏感字段脱敏工具函数
 * 对应 spec/01-constraints.md §操作日志 脱敏规则
 */

/**
 * 密码脱敏：替换为 ***
 */
export function maskPassword(_password: string): string {
  return '***'
}

/**
 * 手机号脱敏：中间四位替换为 ****
 * 例：13812345678 → 138****5678
 */
export function maskPhone(phone: string): string {
  if (!phone || phone.length < 7) {
    return phone
  }
  return phone.replace(/^(\d{3})\d{4}(\d{4})$/, '$1****$2')
}

/**
 * 身份证号脱敏：中间段替换为 ******
 * 例：110101199001011234 → 110101******1234
 */
export function maskIdCard(idCard: string): string {
  if (!idCard || idCard.length < 8) {
    return idCard
  }
  return idCard.replace(/^(.{6})[\d]{8}(.{4})$/, '$1********$2')
}

/**
 * 日期格式化工具
 *
 * @param date - Date 对象或时间戳字符串
 * @param format - 格式字符串，支持 YYYY、MM、DD、HH、mm、ss
 * @returns 格式化后的日期字符串
 */
export function formatDate(
  date: Date | string | number,
  format = 'YYYY-MM-DD HH:mm:ss',
): string {
  const d = date instanceof Date ? date : new Date(date)
  if (isNaN(d.getTime())) {
    return ''
  }

  const year = d.getFullYear().toString()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  const seconds = String(d.getSeconds()).padStart(2, '0')

  return format
    .replace('YYYY', year)
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds)
}

/**
 * 文件大小格式化
 *
 * @param bytes - 字节数
 * @returns 格式化后的大小字符串，如 "1.23 MB"
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  const exponent = Math.min(
    Math.floor(Math.log(bytes) / Math.log(1024)),
    units.length - 1,
  )
  const value = bytes / Math.pow(1024, exponent)
  return `${value.toFixed(2)} ${units[exponent]}`
}

/**
 * 判断是否拥有某个权限
 *
 * @param authorities - 当前用户的权限列表
 * @param permission - 需要检查的权限字符串
 * @returns 是否拥有该权限
 */
export function hasPermission(
  authorities: string[],
  permission: string,
): boolean {
  return authorities.includes(permission)
}

/**
 * 判断是否拥有任意一个权限（OR 逻辑）
 *
 * @param authorities - 当前用户的权限列表
 * @param permissions - 需要检查的权限字符串数组
 * @returns 是否拥有至少一个权限
 */
export function hasAnyPermission(
  authorities: string[],
  permissions: string[],
): boolean {
  return permissions.some((p) => authorities.includes(p))
}

/**
 * 判断是否拥有全部权限（AND 逻辑）
 *
 * @param authorities - 当前用户的权限列表
 * @param permissions - 需要检查的权限字符串数组
 * @returns 是否拥有全部权限
 */
export function hasAllPermissions(
  authorities: string[],
  permissions: string[],
): boolean {
  return permissions.every((p) => authorities.includes(p))
}
