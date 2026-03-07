---
phase: 43
title: "租户域名识别 (Tenant Domain Recognition)"
targets:
  backend: true
  frontend: false
depends_on: [42]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/db/migration/V043__create_tenant_domain.sql"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/entity/TenantDomain.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/infra/mapper/TenantDomainMapper.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/appservice/TenantDomainAppService.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/controller/TenantDomainController.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/filter/TenantDomainFilter.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/dto/TenantDomainCreateDTO.java"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/domain/vo/TenantDomainVO.java"
---
# Phase 43 — 租户域名识别

| 项目 | 值 |
|-----|---|
| Phase | 43 |
| 模块 | ljwx-platform-app (后端) + ljwx-platform-web (过滤器) |
| Feature | L1-D01-F02 |
| 前置依赖 | Phase 42 (超级管理员机制) |
| 测试契约 | `spec/tests/phase-43-tenant-domain.tests.yml` |
| 优先级 | 🟡 **P1 - SaaS 多租户体验** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/04-database.md` — §租户域名表
- `spec/03-api.md` — §租户域名 API
- `spec/01-constraints.md` — §审计字段
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前系统通过 `X-Tenant-Id` header 识别租户,用户体验不佳,无法实现真正的 SaaS 多租户域名隔离。

**解决方案**: 实现租户域名识别功能,支持:
1. 租户绑定自定义域名（如 `tenant1.ljwx.com`）
2. 通过域名自动识别租户
3. 域名缓存（Caffeine L1 + Redis L2）
4. 域名唯一性校验
5. 域名状态管理（启用/禁用）

---

## 数据库契约

### 表结构：sys_tenant_domain

| 列名 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, NOT NULL | 主键（雪花 ID） |
| domain | VARCHAR(200) | NOT NULL, UNIQUE, INDEX | 域名 |
| tenant_id | BIGINT | NOT NULL, INDEX | 租户 ID |
| status | VARCHAR(20) | NOT NULL, DEFAULT 'ENABLED' | ENABLED / DISABLED |
| is_primary | BOOLEAN | NOT NULL, DEFAULT FALSE | 是否主域名 |
| verified | BOOLEAN | NOT NULL, DEFAULT FALSE | 是否已验证 |
| verified_time | TIMESTAMP | | 验证时间 |
| verify_token | VARCHAR(100) | | 验证 token |
| remark | VARCHAR(500) | | 备注 |
| created_by | BIGINT | NOT NULL, DEFAULT 0 | 创建人 |
| created_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_by | BIGINT | NOT NULL, DEFAULT 0 | 更新人 |
| updated_time | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | 更新时间 |
| deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | 软删除 |
| version | INT | NOT NULL, DEFAULT 1 | 乐观锁 |

**索引**:
- `uk_domain` (domain, deleted) UNIQUE
- `idx_tenant_id` (tenant_id)
- `idx_status` (status)

> 审计字段（最后 7 列）由 BaseEntity 自动管理,禁止在 DTO 中声明。
> 注意: tenant_id 不在审计字段中,是业务字段。

### Flyway 文件

| 文件 | 内容 |
|------|------|
| `V043__create_tenant_domain.sql` | 建表 + 索引 |

禁止：`IF NOT EXISTS`、在建表文件中写 DML。

---

## API 契约

| 方法 | 路径 | 权限标识 | 请求体 | 响应体 | 说明 |
|------|------|----------|--------|--------|---------|
| GET | /api/v1/tenant/domains | tenant:domain:list | — (Query Parameters) | Result<List<TenantDomainVO>> | 查询当前租户域名列表 |
| GET | /api/v1/tenant/domains/{id} | tenant:domain:query | — | Result<TenantDomainVO> | 查询域名详情 |
| POST | /api/v1/tenant/domains | tenant:domain:add | TenantDomainCreateDTO | Result<Long> | 创建域名 |
| PUT | /api/v1/tenant/domains/{id} | tenant:domain:edit | TenantDomainUpdateDTO | Result<Void> | 更新域名 |
| DELETE | /api/v1/tenant/domains/{id} | tenant:domain:delete | — | Result<Void> | 删除域名（软删） |
| POST | /api/v1/tenant/domains/{id}/verify | tenant:domain:verify | — | Result<Void> | 验证域名 |
| POST | /api/v1/tenant/domains/{id}/set-primary | tenant:domain:setPrimary | — | Result<Void> | 设置为主域名 |

---

## DTO / VO 契约

### TenantDomainCreateDTO（创建请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| domain | String | @NotBlank, @Pattern(regexp="^[a-z0-9.-]+$"), @Size(max=200) | 域名 |
| isPrimary | Boolean | @NotNull | 是否主域名 |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`、`tenantId`、`status`、`verified`、`verifiedTime`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### TenantDomainUpdateDTO（更新请求）

| 字段 | 类型 | 校验 | 说明 |
|------|------|------|------|
| status | String | @NotBlank | ENABLED / DISABLED |
| remark | String | @Size(max=500) | 备注 |

**禁止字段**：`id`、`tenantId`、`domain`、`isPrimary`、`verified`、`verifiedTime`、`createdBy`、`createdTime`、`updatedBy`、`updatedTime`、`deleted`、`version`

### TenantDomainVO（响应）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 主键 |
| domain | String | 域名 |
| tenantId | Long | 租户 ID |
| status | String | 状态 |
| isPrimary | Boolean | 是否主域名 |
| verified | Boolean | 是否已验证 |
| verifiedTime | LocalDateTime | 验证时间 |
| remark | String | 备注 |
| createdTime | LocalDateTime | 创建时间 |
| updatedTime | LocalDateTime | 更新时间 |

**禁止字段**：`deleted`、`createdBy`、`updatedBy`、`version`

---

## 业务规则

> 格式：BL-43-{序号}：[条件] → [动作] → [结果/异常]

- **BL-43-01**：创建域名 → 检查域名唯一性 → 重复则抛出 `BusinessException(DOMAIN_EXISTS)`
- **BL-43-02**：创建域名 → 检查域名格式 → 不符合则抛出 `BusinessException(INVALID_DOMAIN_FORMAT)`
- **BL-43-03**：设置主域名 → 取消当前租户其他主域名 → 仅保留一个主域名
- **BL-43-04**：删除主域名 → 检查是否为主域名 → 是则抛出 `BusinessException(CANNOT_DELETE_PRIMARY_DOMAIN)`
- **BL-43-05**：请求到达 → TenantDomainFilter 从 Host header 提取域名 → 查询 domainCache → 设置 TenantContext
- **BL-43-06**：域名缓存未命中 → 查询数据库 → 回填缓存（Caffeine L1 + Redis L2）
- **BL-43-07**：域名更新/删除 → 失效 domainCache → 广播 Outbox 事件
- **BL-43-08**：域名验证 → 检查 DNS TXT 记录 → 验证成功则更新 verified=TRUE, verified_time=NOW()
- **BL-43-09**：禁用域名 → 不影响已登录用户 → 新请求无法通过域名识别租户

---

## 缓存策略

```java
@Cacheable(
    cacheName = "domainCache",
    key = "#domain",
    level = CacheLevel.CAFFEINE_REDIS,
    ttl = 300
)
public TenantDomain getByDomain(String domain) {
    // ...
}
```

**缓存失效**:
- 域名创建/更新/删除时,失效 `domainCache:{domain}`
- 通过 Outbox 事件 + Pub/Sub 广播失效

---

## 核心组件契约

### TenantDomainFilter

```java
@Component
@Order(0)  // 必须在 TenantContextFilter 之前执行
public class TenantDomainFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, ...) {
        // 1. 从 Host header 提取域名
        String host = request.getHeader("Host");
        if (host == null) {
            chain.doFilter(request, response);
            return;
        }

        // 2. 去除端口号
        String domain = host.split(":")[0];

        // 3. 查询域名缓存
        TenantDomain tenantDomain = tenantDomainService.getByDomain(domain);
        if (tenantDomain == null || !tenantDomain.getStatus().equals("ENABLED")) {
            chain.doFilter(request, response);
            return;
        }

        // 4. 设置租户上下文
        request.setAttribute("TENANT_ID_FROM_DOMAIN", tenantDomain.getTenantId());

        chain.doFilter(request, response);
    }
}
```

### TenantContextFilter 修改

```java
@Component
@Order(1)  // 在 TenantDomainFilter 之后执行
public class TenantContextFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, ...) {
        try {
            Long tenantId = resolveTenantId(request);
            TenantContext.setTenantId(tenantId);
            chain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }

    private Long resolveTenantId(HttpServletRequest request) {
        // 1. 优先从域名识别
        Long tenantIdFromDomain = (Long) request.getAttribute("TENANT_ID_FROM_DOMAIN");
        if (tenantIdFromDomain != null) {
            return tenantIdFromDomain;
        }

        // 2. 从认证信息获取用户租户
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof LoginUser) {
            LoginUser loginUser = (LoginUser) authentication.getPrincipal();
            Long userTenantId = loginUser.getTenantId();

            // 3. 超级管理员可以通过 header 切换租户
            if (userTenantId != null && userTenantId.longValue() == 0L) {
                String headerTenantId = request.getHeader("X-Tenant-Id");
                if (StringUtils.hasText(headerTenantId)) {
                    return Long.parseLong(headerTenantId);
                }
            }

            return userTenantId;
        }

        // 4. 未认证请求,返回 null
        return null;
    }
}
```

---

## 域名验证流程

### DNS TXT 记录验证

1. 租户创建域名后,系统生成验证 token: `ljwx-verify-{randomString}`
2. 租户在 DNS 中添加 TXT 记录: `_ljwx-verify.{domain}` → `ljwx-verify-{randomString}`
3. 租户点击"验证域名"按钮
4. 系统查询 DNS TXT 记录,验证 token 是否匹配
5. 验证成功后,更新 `verified=TRUE`, `verified_time=NOW()`

```java
public void verifyDomain(Long domainId) {
    TenantDomain domain = tenantDomainRepository.findById(domainId);
    if (domain == null) {
        throw new BusinessException(DOMAIN_NOT_FOUND);
    }

    // 查询 DNS TXT 记录
    String expectedToken = domain.getVerifyToken();
    String actualToken = dnsService.queryTxtRecord("_ljwx-verify." + domain.getDomain());

    if (!expectedToken.equals(actualToken)) {
        throw new BusinessException(DOMAIN_VERIFY_FAILED);
    }

    // 更新验证状态
    domain.setVerified(true);
    domain.setVerifiedTime(LocalDateTime.now());
    tenantDomainRepository.update(domain);

    // 失效缓存
    cacheManager.evict("domainCache", domain.getDomain());
}
```

---

## 测试用例（摘要）

详细用例见 **`spec/tests/phase-43-tenant-domain.tests.yml`**。

P0 强制覆盖（Gate R09 检查）：

| ID | 场景 | P |
|----|------|---|
| TC-43-01 | 无 Token → 401 | P0 |
| TC-43-02 | 无权限 → 403 | P0 |
| TC-43-03 | 正常 CRUD | P0 |
| TC-43-04 | 域名唯一性校验 | P0 |
| TC-43-05 | 设置主域名 | P0 |
| TC-43-06 | 删除主域名失败 | P0 |
| TC-43-07 | 通过域名识别租户 | P0 |
| TC-43-08 | 域名缓存生效 | P0 |
| TC-43-09 | 域名验证流程 | P1 |

---

## 验收条件

- **AC-01**：Flyway 迁移含 7 列审计字段,无 `IF NOT EXISTS`
- **AC-02**：所有 Controller 方法有 `@PreAuthorize`
- **AC-03**：DTO 不含禁止字段
- **AC-04**：域名唯一性校验生效
- **AC-05**：设置主域名时取消其他主域名
- **AC-06**：删除主域名时拒绝
- **AC-07**：TenantDomainFilter 正确识别租户
- **AC-08**：域名缓存生效（Caffeine L1 + Redis L2）
- **AC-09**：域名更新/删除后缓存失效
- **AC-10**：编译通过,所有 P0 用例通过

---

## 关键约束（硬规则速查）

- 审计字段：7 列 NOT NULL + DEFAULT,禁止在 DTO 中声明
- 权限格式：`hasAuthority('tenant:domain:list')` —— 无 ROLE_ 前缀
- 禁止：`IF NOT EXISTS` · 在 DTO 中声明禁止字段
- 域名格式：仅允许小写字母、数字、点、连字符
- 主域名：每个租户仅允许一个主域名
- 缓存策略：CAFFEINE_REDIS,TTL 300s
- Filter 顺序：TenantDomainFilter (Order=0) → TenantContextFilter (Order=1)

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-43-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-43-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-43-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-43-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-43-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-43-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-43-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-43-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-43-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-43-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
