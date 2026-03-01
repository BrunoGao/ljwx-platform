---
phase: 38
title: "租户品牌配置 (Tenant Branding)"
targets:
  backend: true
  frontend: true
depends_on: [37]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V038__create_tenant_brand.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/TenantBrand.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/TenantBrandMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/TenantBrandAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/TenantBrandController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/TenantBrandUpdateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/TenantBrandVO.java"
  - "ljwx-platform-admin/src/api/tenantBrand.ts"
  - "ljwx-platform-admin/src/stores/tenantBrand.ts"
  - "ljwx-platform-admin/src/views/tenant/brand/index.vue"
---
# Phase 38 — 租户品牌配置

| 项目 | 值 |
|-----|---|
| Phase | 38 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-admin (前端) |
| Feature | L1-D03-F01 |
| 前置依赖 | Phase 37 (Grafana 仪表盘) |
| 测试契约 | `spec/tests/phase-38-tenant-brand.tests.yml` |
| 优先级 | 🔴 **P0 - 影响租户体验** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §租户品牌配置表
- `spec/03-api.md` — §租户品牌 API
- `spec/01-constraints.md` — §审计字段、§TypeScript 约束
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 无法实现租户级 UI 定制,所有租户使用相同的品牌样式。

**解决方案**: 实现租户品牌配置功能,支持 6 大分类:
1. 基础信息（名称、Logo、Favicon）
2. 主题配色（主色、辅助色、背景色）
3. 登录页配置（背景图、标语、版权信息）
4. 导航栏配置（Logo、标题、菜单样式）
5. 页脚配置（版权信息、备案号、链接）
6. 移动端配置（App 图标、启动页）

---

## 数据库契约

### 表结构：sys_tenant_brand

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| brand_name | VARCHAR(100) | NOT NULL | 品牌名称 |
| logo_url | VARCHAR(500) | | Logo URL |
| favicon_url | VARCHAR(500) | | Favicon URL |
| primary_color | VARCHAR(20) | NOT NULL, DEFAULT '#1890ff' | 主色 |
| secondary_color | VARCHAR(20) | | 辅助色 |
| background_color | VARCHAR(20) | | 背景色 |
| login_bg_url | VARCHAR(500) | | 登录页背景图 |
| login_slogan | VARCHAR(200) | | 登录页标语 |
| copyright_text | VARCHAR(200) | | 版权信息 |
| icp_number | VARCHAR(50) | | 备案号 |
| footer_links | JSONB | | 页脚链接 |
| mobile_icon_url | VARCHAR(500) | | 移动端图标 |
| mobile_splash_url | VARCHAR(500) | | 移动端启动页 |
| custom_css | TEXT | | 自定义 CSS |
| tenant_id | BIGINT | NOT NULL, DEFAULT 0, INDEX | 框架自动填充 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_tenant_id` (tenant_id, deleted) UNIQUE
- `idx_tenant_id` (tenant_id)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。
> 注意: tenant_id 仅在审计字段中出现一次,用于租户隔离。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V038__create_tenant_brand.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|------|
| GET | /api/v1/tenant/brand | tenant:brand:list | — | Result<TenantBrandVO> | 查询当前租户品牌配置 |
| PUT | /api/v1/tenant/brand | tenant:brand:edit | TenantBrandUpdateDTO | Result<Void> | 更新品牌配置 |

---

## DTO / VO 契约

### TenantBrandUpdateDTO（更新请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| brandName | String | @NotBlank | 品牌名称 |
| logoUrl | String | @URL | Logo URL |
| faviconUrl | String | @URL | Favicon URL |
| primaryColor | String | @Pattern(regexp="^#[0-9A-Fa-f]{6}$") | 主色 |
| secondaryColor | String | @Pattern | 辅助色 |
| backgroundColor | String | @Pattern | 背景色 |
| loginBgUrl | String | @URL | 登录页背景图 |
| loginSlogan | String | @Size(max=200) | 登录页标语 |
| copyrightText | String | @Size(max=200) | 版权信息 |
| icpNumber | String | @Size(max=50) | 备案号 |
| footerLinks | List<FooterLink> | | 页脚链接 |
| mobileIconUrl | String | @URL | 移动端图标 |
| mobileSplashUrl | String | @URL | 移动端启动页 |
| customCss | String | @Size(max=10000) | 自定义 CSS |

**禁止字段**：`id`、`tenantId`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### TenantBrandVO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| brandName | String | 品牌名称 |
| logoUrl | String | Logo URL |
| faviconUrl | String | Favicon URL |
| primaryColor | String | 主色 |
| secondaryColor | String | 辅助色 |
| backgroundColor | String | 背景色 |
| loginBgUrl | String | 登录页背景图 |
| loginSlogan | String | 登录页标语 |
| copyrightText | String | 版权信息 |
| icpNumber | String | 备案号 |
| footerLinks | List<FooterLink> | 页脚链接 |
| mobileIconUrl | String | 移动端图标 |
| mobileSplashUrl | String | 移动端启动页 |
| customCss | String | 自定义 CSS |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`tenantId`、`deleted`、`createdBy`、`updatedBy`、`version`

---

## 业务规则

> 格式：BL-38-{序号}：[条件] → [动作] → [结果/异常]

- **BL-38-01**：租户首次访问 → 自动创建默认品牌配置 → 使用系统默认值
- **BL-38-02**：更新品牌配置 → 失效 brandCache → 广播 Outbox 事件
- **BL-38-03**：前端加载 → 从 brandCache 读取 → Caffeine L1 + Redis L2
- **BL-38-04**：自定义 CSS → 过滤危险代码 → 禁止 `<script>`、`javascript:`
- **BL-38-05**：颜色值 → 校验格式 → 必须为 `#RRGGBB` 格式
- **BL-38-06**：Logo/图标 → 限制大小 → 最大 2MB
- **BL-38-07**：页脚链接 → 最多 10 个 → 超出拒绝

---

## 缓存策略

```java
@Cacheable(
    cacheName = "brandCache",
    key = "#tenantId",
    level = CacheLevel.CAFFEINE_REDIS,
    ttl = 3600
)
public TenantBrandVO getBrandByTenantId(Long tenantId) {
    // ...
}
```

---

## 前端集成

### 品牌配置 Store

```typescript
export const useTenantBrandStore = defineStore('tenantBrand', {
  state: () => ({
    brand: null as TenantBrandVO | null,
  }),
  actions: {
    async loadBrand() {
      const res = await getTenantBrand()
      this.brand = res.data
      this.applyBrand()
    },
    applyBrand() {
      if (!this.brand) return
      // 应用主题色
      document.documentElement.style.setProperty('--primary-color', this.brand.primaryColor)
      // 应用 Favicon
      const favicon = document.querySelector('link[rel="icon"]')
      if (favicon) favicon.setAttribute('href', this.brand.faviconUrl)
      // 应用自定义 CSS
      if (this.brand.customCss) {
        const style = document.createElement('style')
        style.textContent = this.brand.customCss
        document.head.appendChild(style)
      }
    },
  },
})
```

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-38-tenant-brand.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-38-01 | 无 Token → 401 | P0 |
| TC-38-02 | 无权限 → 403 | P0 |
| TC-38-03 | 查询品牌配置 | P0 |
| TC-38-04 | 更新品牌配置 | P0 |
| TC-38-05 | 缓存失效 | P0 |
| TC-38-06 | 自定义 CSS 过滤 | P0 |
| TC-38-07 | 颜色值校验 | P0 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：DTO 不含 `tenantId` 及其他禁止字段
- **AC-04**：品牌配置缓存生效（Caffeine L1 + Redis L2）
- **AC-05**：更新品牌配置后缓存失效
- **AC-06**：自定义 CSS 过滤危险代码
- **AC-07**：前端正确应用品牌配置
- **AC-08**：编译通过,前端 `type-check` 通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 权限格式：`hasAuthority('tenant:brand:view')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · `tenantId` in DTO · `any` in TypeScript
- 前端版本号：仅 `~`（tilde），禁止 `^`（caret）
- 缓存策略：CAFFEINE_REDIS,TTL 3600s
- 自定义 CSS：必须过滤 `<script>`、`javascript:`
