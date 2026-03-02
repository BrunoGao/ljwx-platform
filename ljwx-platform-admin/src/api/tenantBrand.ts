import request from './request'

/**
 * 页脚链接
 */
export interface FooterLink {
  /** 链接文本 */
  text: string
  /** 链接地址 */
  url: string
}

/**
 * 租户品牌配置 VO
 */
export interface TenantBrandVO {
  /** 主键 */
  id: number
  /** 品牌名称 */
  brandName: string
  /** Logo URL */
  logoUrl: string | null
  /** Favicon URL */
  faviconUrl: string | null
  /** 主色 */
  primaryColor: string
  /** 辅助色 */
  secondaryColor: string | null
  /** 背景色 */
  backgroundColor: string | null
  /** 登录页背景图 */
  loginBgUrl: string | null
  /** 登录页标语 */
  loginSlogan: string | null
  /** 版权信息 */
  copyrightText: string | null
  /** 备案号 */
  icpNumber: string | null
  /** 页脚链接 */
  footerLinks: FooterLink[] | null
  /** 移动端图标 */
  mobileIconUrl: string | null
  /** 移动端启动页 */
  mobileSplashUrl: string | null
  /** 自定义 CSS */
  customCss: string | null
  /** 创建时间 */
  createdTime: string
  /** 更新时间 */
  updatedTime: string
}

/**
 * 租户品牌配置更新 DTO
 */
export interface TenantBrandUpdateDTO {
  /** 品牌名称 */
  brandName: string
  /** Logo URL */
  logoUrl?: string
  /** Favicon URL */
  faviconUrl?: string
  /** 主色 */
  primaryColor?: string
  /** 辅助色 */
  secondaryColor?: string
  /** 背景色 */
  backgroundColor?: string
  /** 登录页背景图 */
  loginBgUrl?: string
  /** 登录页标语 */
  loginSlogan?: string
  /** 版权信息 */
  copyrightText?: string
  /** 备案号 */
  icpNumber?: string
  /** 页脚链接 */
  footerLinks?: FooterLink[]
  /** 移动端图标 */
  mobileIconUrl?: string
  /** 移动端启动页 */
  mobileSplashUrl?: string
  /** 自定义 CSS */
  customCss?: string
}

/**
 * 获取当前租户品牌配置
 */
export function getTenantBrand(): Promise<TenantBrandVO> {
  return request.get<TenantBrandVO>('/api/v1/tenant/brand')
}

/**
 * 更新租户品牌配置
 */
export function updateTenantBrand(data: TenantBrandUpdateDTO): Promise<void> {
  return request.put<void>('/api/v1/tenant/brand', data)
}
