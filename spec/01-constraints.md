# 硬约束

> 所有版本号见 CLAUDE.md "版本锁定"段，本文件不重复。

## 审计字段

所有业务表（Quartz 系统表除外）必须包含以下 7 列：

```sql
tenant_id     BIGINT       NOT NULL,
created_by    BIGINT       NOT NULL DEFAULT 0,
created_time  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_by    BIGINT       NOT NULL DEFAULT 0,
updated_time  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
deleted       BOOLEAN      NOT NULL DEFAULT FALSE,
version       INT          NOT NULL DEFAULT 1
```

**规则：** NOT NULL + 有 DEFAULT，因此 INSERT 时即使拦截器未触发也不会报错。AuditFieldInterceptor（MyBatis Interceptor）在 INSERT/UPDATE 时从 CurrentUserHolder（core 接口）读取当前用户 ID 写入 created_by / updated_by。

**验收检查：** 每个 Flyway migration 中的 CREATE TABLE（Quartz 表除外）必须包含这 7 列关键字。gate-manifest.sh 中循环检查全部 7 列。

## 多租户行级隔离

所有查询通过 TenantLineInterceptor（MyBatis Interceptor）自动追加 WHERE tenant_id = ?。tenant_id 取自 CurrentTenantHolder.get()（core 接口）。DTO 中禁止出现 tenant_id 字段。前端禁止传递 tenant_id。

## JWT 认证

| 项目 | 值 |
|------|-----|
| Access Token 有效期 | 30 min |
| Refresh Token 有效期 | 7 days |
| 签名算法 | HS256 |
| Payload claims | sub(userId), tenantId, username, type("access"|"refresh"), authorities(权限字符串数组) |
| authorities claim name | authorities（自定义 claim，非 Spring 默认 scope） |
| authorities converter | 自定义 JwtAuthenticationConverter：读取 authorities claim → 转为 SimpleGrantedAuthority，不添加 ROLE_ 前缀 |
| ROLE_ 前缀 | 不使用。RBAC 权限均为 resource:action 格式。`@PreAuthorize("hasAuthority('user:read')")` |
| 密钥配置 | application.yml 中 ljwx.jwt.secret 占位，.env.example 提供示例值 |

**Refresh 流程：** 前端 Axios 拦截 401 → 用 refresh token 调 /api/auth/refresh → 成功则重放原请求 → 失败则跳转登录。

## RBAC 权限

种子数据权限字符串（写入 sys_permission 表）：

```
user:read, user:write, user:delete,
role:read, role:write, role:delete,
tenant:read, tenant:write,
job:read, job:write, job:execute,
dict:read, dict:write,
config:read, config:write,
log:read, log:export,
file:read, file:upload, file:delete,
notice:read, notice:write,
screen:read
```

默认 admin 用户拥有全部权限。Controller 方法必须标注 @PreAuthorize。

## Quartz 调度

作业存储 per-tenant 隔离：JobKey(name="{jobId}", group="TENANT_{tenantId}")。Quartz 表使用标准 QRTZ_ 前缀，由 Flyway V010 脚本创建（不使用 IF NOT EXISTS，Quartz 表不含审计字段）。

## 操作日志

异步记录，独立线程池（core size=2, max=4, queue=1024）。日志体超 4096 字节截断。敏感字段脱敏规则：password → ***，phone → 中间四位 *，idCard → 中间段 *。

## 文件管理

Snowflake ID 命名。上传限制 50 MB。白名单后缀：jpg, jpeg, png, gif, webp, svg, pdf, doc, docx, xls, xlsx, ppt, pptx, txt, csv, zip, rar, 7z, mp4, mp3。存储路径 `${ljwx.file.base-path}/tenant_{tenantId}/{yyyy}/{MM}/{dd}/`。

## 缓存策略

字典（dict）和系统配置（config）使用 JVM 本地缓存（Caffeine，由 Spring Boot 管理）。TTL = 10 min。不使用 Redis / MQ / JPA。

## TypeScript 约束

禁止 any 类型。tsconfig.json 开启 strict: true。所有 API 返回值必须有类型定义（放在 packages/shared/src/types/）。

## Vue Router 5 兼容性约束

路由实现必须以 vue-router @~5.0.2 的 API 为准。Vue Router 5 相对 v4 有关键变更（如将 unplugin-vue-router 合并进核心包，路由文件约定发生变化）。以官方文档（https://router.vuejs.org/guide/migration/v4-to-v5）与类型定义为准，禁止按 v4 经验写代码。若某个 v4 API 在 v5 中已被标记 deprecated 或移除，必须使用 v5 推荐的替代方案。
