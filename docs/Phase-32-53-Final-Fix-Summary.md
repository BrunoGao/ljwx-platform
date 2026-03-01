# Phase 32-53 深度评审修复总结

## 修复概览

**总问题数**: 26 个
**已修复**: 11 个
**剩余**: 15 个

## ✅ 已完成修复 (11/26)

### 🔴 CRITICAL 问题修复 (5/6)

#### C-1: Flyway 版本号乱序 ✅
**文件**: `spec/registry/migrations.yml`

```yaml
# 修复前
- version: "035" phase: 40  # Phase 40 先于 Phase 38 执行会失败
- version: "037" phase: 41
- version: "038" phase: 38

# 修复后
- version: "040" phase: 40  # 与 Phase 号对齐
- version: "041" phase: 40
- version: "042" phase: 41
- version: "038" phase: 38  # 保持不变
```

#### C-2: Phase 34 DAG 违规 ✅
**文件**: `spec/phase/phase-34.md`

```yaml
# 修复前
scope:
  - "ljwx-platform-core/.../OutboxEventPoller.java"  # ❌ core 依赖 app

# 修复后
scope:
  - "ljwx-platform-app/.../OutboxEventPoller.java"   # ✅ 移至 app
```

#### C-3: Phase 41 DAG 违规 ✅
**文件**: `spec/phase/phase-41.md`

**架构调整**:
- TenantLifecycleFilter 通过 Redis 缓存查询租户状态
- app 模块监听 TenantStatusQueryEvent 并更新缓存
- 避免 web → app 直接依赖

```java
// 修复前 (web 依赖 app)
Tenant tenant = tenantService.getById(tenantId);

// 修复后 (通过 Redis 缓存解耦)
String cacheKey = "tenant:status:" + tenantId;
String status = redisTemplate.opsForValue().get(cacheKey);
```

#### C-4: Phase 43 DAG 违规 ✅
**文件**: `spec/phase/phase-43.md`

```java
// 修复前 (web 依赖 app)
TenantDomain tenantDomain = tenantDomainService.getByDomain(domain);

// 修复后 (通过 Redis 缓存解耦)
String cacheKey = "tenant:domain:" + domain;
Long tenantId = redisTemplate.opsForValue().get(cacheKey);
```

#### C-6: Phase 45 DAG 违规 ✅
**文件**: `spec/phase/phase-45.md`

```yaml
# 修复前
scope:
  - "ljwx-platform-core/.../TaskExecutionLogger.java"  # ❌ core 依赖 app

# 修复后
scope:
  - "ljwx-platform-app/.../TaskExecutionLogger.java"   # ✅ 移至 app
```

### 🟠 高危问题修复 (2/6)

#### H-4: Phase 43 缺失字段 ✅
**文件**: `spec/phase/phase-43.md`

```sql
-- 添加缺失的 verify_token 字段
CREATE TABLE sys_tenant_domain (
    -- ... 其他字段
    verify_token VARCHAR(64),
    verify_method VARCHAR(20) NOT NULL DEFAULT 'DNS_TXT',
    verify_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    verified_at TIMESTAMP
);
```

#### H-5: Phase 34 缺失文件 ✅
**文件**: `spec/phase/phase-34.md`

```yaml
scope:
  - "ljwx-platform-app/.../OutboxEventNotificationListener.java"  # 添加
```

### 🟡 中等问题修复 (2/6)

#### M-4: Phase 50 变量占位符冲突 ✅
**文件**: `spec/phase/phase-50.md`

```yaml
# 修复前
- BL-50-01: 模板变量 → ${variable_name} 格式  # 与 Spring EL 冲突

# 修复后
- BL-50-01: 模板变量 → {{variable_name}} 格式 (Mustache 风格)
```

#### M-5: Phase 43 引用修复 ✅
**文件**: `spec/phase/phase-43.md`

```yaml
# 修复前
读取清单:
  - spec/registry/constraints.yml  # 不存在

# 修复后
读取清单:
  - spec/registry/permissions.yml
  - spec/registry/migrations.yml
```

### 🔵 质量退化修复 (2/8)

#### M-6: Phase 53 ADR 引用错误 ✅
**文件**: `spec/phase/phase-53.md` + `docs/adr/ADR-0009-workflow-visibility.md`

```yaml
# 修复前
- BL-53-04: 可见性模型 → 6 级 (ADR-0008)  # 应该是 ADR-0009

# 修复后
- BL-53-04: 可见性模型 → 6 级 (ADR-0009)
```

**新增文档**: `docs/adr/ADR-0009-workflow-visibility.md` - 工作流可见性模型 (6 级)

#### Phase 46-53 质量补全 ✅
**所有 Phase 46-53 已补全**:
1. ✅ YAML frontmatter 添加 scope 字段
2. ✅ 添加"读取清单"部分
3. ✅ 补全数据库契约表格 (展开 "+ 7 审计字段")
4. ✅ 添加"核心组件契约"部分 (Entity/DTO/VO/Controller 代码签名)
5. ✅ 添加"前端文件路径"表格
6. ✅ 在 Overview 表格中添加完整信息 (模块/Feature/前置依赖/测试契约)

**已补全的 Phase**:
- Phase 46: 导入导出中心
- Phase 47: 开放 API 管理 - 应用管理
- Phase 48: 开放 API 管理 - 密钥管理
- Phase 49: Webhook 事件推送
- Phase 50: 消息中台 - 模板管理
- Phase 51: 消息中台 - 消息记录
- Phase 52: 消息中台 - 订阅管理
- Phase 53: 流程引擎 (简化版)

---

## ⚠️ 剩余待修复问题 (15/26)

### 🔴 CRITICAL (1/6)

#### C-5: Phase 44 DAG 违规 + PostgreSQL 不兼容
**问题**:
1. DataScopeInterceptor 在 data 模块调用 SecurityUtils.getLoginUser() (security 模块)
2. 使用 MySQL find_in_set() 函数,PostgreSQL 不支持

**修复方案**:
```java
// 方案 1: 通过 ThreadLocal 传递用户信息（避免跨模块依赖）
public class DataScopeContext {
    private static final ThreadLocal<DataScopeInfo> CONTEXT = new ThreadLocal<>();

    public static void set(Long userId, Long deptId, String dataScope) {
        CONTEXT.set(new DataScopeInfo(userId, deptId, dataScope));
    }
}

// 方案 2: PostgreSQL 兼容的部门树查询
// 替换 find_in_set(?, ancestors)
// 使用: ancestors @> ARRAY[?]::bigint[] 或 WITH RECURSIVE CTE
```

### 🟠 高危问题 (4/6)

#### H-1: Phase 33 @Cacheable 命名冲突
**问题**: 自定义 @Cacheable 注解与 Spring 内置注解冲突

**修复方案**: 重命名为 @MultiLevelCacheable 或使用完整包名

#### H-2: Phase 42 Long == 比较
**问题**: `loginUser.getTenantId() == 0` 使用 == 比较 Long 对象

**修复方案**: 使用 `Long.valueOf(0).equals(loginUser.getTenantId())`

#### H-3: Phase 44 SQL 注入防护矛盾
**问题**: 声称使用 PreparedStatement 但代码中直接拼接 SQL

**修复方案**: 使用 MyBatis 参数化查询或 PreparedStatement

#### H-6: Phase 48/49 HMAC 实现错误
**问题**: 描述为字符串拼接,不是真正的 HMAC-SHA256

**修复方案**: 使用 `javax.crypto.Mac` 实现真正的 HMAC

### 🟡 中等问题 (4/6)

#### M-1: Phase 38 CSS 注入防护
**问题**: customCss 直接注入 DOM,缺乏 CSS 属性白名单

**修复方案**: 添加 CSS 属性白名单验证

#### M-2: Phase 35 Filter 时序问题
**问题**: LoggingFilter 在 TenantContext 设置前执行

**修复方案**: 调整 Filter 顺序,确保 TenantContextFilter 先执行

#### M-3: Phase 36 指标重复
**问题**: http_requests_total 与 Spring Actuator 重复

**修复方案**: 使用 Spring Boot 内置指标,移除自定义指标

#### M-6: Phase 53 ADR 引用错误 (已修复)

### 🔵 质量退化 (6/8)

- Phase 46-53 质量补全 (已完成)

---

## 关键约束 (硬规则)

### DAG 依赖规则
```
core ← {security, data} ← web ← app
```
- core 不能依赖任何模块
- security/data 只能依赖 core
- web 只能依赖 core/security/data
- app 可以依赖所有模块

### Flyway 版本号规则
- 格式: `VNNN__description.sql`
- NNN 必须唯一且递增
- 建议与 Phase 号对齐（避免乱序）

### 审计字段 (7 个必须字段)
```sql
tenant_id BIGINT NOT NULL DEFAULT 0,
created_by BIGINT NOT NULL DEFAULT 0,
created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_by BIGINT NOT NULL DEFAULT 0,
updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
deleted BOOLEAN NOT NULL DEFAULT FALSE,
version INT NOT NULL DEFAULT 1
```

### PostgreSQL 兼容性
- 禁止使用 MySQL 专有函数: `find_in_set()`, `GROUP_CONCAT()` 等
- 使用 PostgreSQL 数组: `@>`, `&&`, `ARRAY[]`
- 使用 CTE 递归查询替代层级查询

---

## 技术栈
- 数据库: PostgreSQL 14+
- 缓存: Caffeine (L1) + Redis (L2)
- 迁移: Flyway
- 认证: HMAC + timestamp + nonce

---

## 下一步行动

1. **修复 C-5**: Phase 44 DAG 违规 + PostgreSQL 不兼容 (最高优先级)
2. **修复 H-1 到 H-6**: 高危问题
3. **修复 M-1 到 M-3**: 中等问题
4. **提交到 GitHub master**: 所有修复完成后提交

---

**生成时间**: 2025-01-XX
**修复进度**: 11/26 (42%)
