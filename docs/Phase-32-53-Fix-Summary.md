# Phase 32-53 修复总结报告

## 已完成修复 ✅

### 1. C-1: Flyway 版本号乱序 ✅
**问题**: Phase 38 使用 V038,但 Phase 40/41 使用 V035-V037,导致执行顺序错误

**修复**:
- Phase 35-37: 预留给其他 Phase
- Phase 38: V038-V039 (保持不变)
- Phase 40: V040-V041 (从 V035-V036 改为 V040-V041)
- Phase 41: V042 (从 V037 改为 V042)

**影响文件**: `spec/registry/migrations.yml`

### 2. C-2: Phase 34 DAG 违规 ✅
**问题**: OutboxEventPoller 在 core 模块但依赖 app 模块的 Mapper

**修复**: 将 OutboxEventPoller 和 OutboxEventNotificationListener 移至 app 模块

**影响文件**: `spec/phase/phase-34.md`

### 3. C-3: Phase 41 DAG 违规 ✅
**问题**: TenantLifecycleFilter 在 web 模块但依赖 app 模块的 Service

**修复**: 将 TenantLifecycleFilter 移至 app 模块,可以直接查询 Repository

**影响文件**: `spec/phase/phase-41.md`

### 4. C-4: Phase 43 DAG 违规 ✅
**问题**: TenantDomainFilter 在 web 模块但依赖 app 模块的 Service

**修复**: 将 TenantDomainFilter 移至 app 模块

**影响文件**: `spec/phase/phase-43.md`

### 5. H-4: Phase 43 缺少 verify_token 字段 ✅
**问题**: 代码使用了 getVerifyToken() 但表结构没有此列

**修复**: 在 sys_tenant_domain 表中添加 verify_token VARCHAR(100) 列

**影响文件**: `spec/phase/phase-43.md`

### 6. M-5: Phase 43 引用不存在的文件 ✅
**问题**: 读取清单中引用了 `spec/registry/constraints.yml`,但此文件不存在

**修复**: 从读取清单中移除此引用

**影响文件**: `spec/phase/phase-43.md`

### 7. C-6: Phase 45 DAG 违规 ✅
**问题**: TaskExecutionLogger 在 core 模块但需要依赖 app 模块

**修复**: 将 TaskExecutionLogger 移至 app 模块

**影响文件**: `spec/phase/phase-45.md`

---

## 待修复问题 ⚠️

### CRITICAL 问题

#### C-5: Phase 44 DAG 违规 + PostgreSQL 不兼容 ⚠️
**问题 1**: DataScopeInterceptor 在 data 模块但调用 SecurityUtils.getLoginUser() (security 模块)
**问题 2**: 使用 MySQL 的 find_in_set() 函数,PostgreSQL 不支持

**建议修复方案**:
1. 通过 ThreadLocal 或 Request Attribute 传递用户信息,避免直接依赖 security 模块
2. 将 find_in_set() 改为 PostgreSQL 兼容的查询:
   ```sql
   -- MySQL: find_in_set(#{userDeptId}, ancestors)
   -- PostgreSQL: ancestors @> ARRAY[#{userDeptId}]::bigint[]
   或使用 CTE 递归查询
   ```

**影响文件**: `spec/phase/phase-44.md`

### 高危问题

#### H-1: Phase 33 命名冲突
**问题**: @Cacheable 与 Spring 内置注解同名

**建议**: 重命名为 @LjwxCacheable 或 @MultiLevelCacheable

#### H-2: Phase 42 Long 比较 bug
**问题**: `userTenantId == 0` 应该用 equals()

**建议**: 改为 `Long.valueOf(0).equals(userTenantId)` 或 `userTenantId.longValue() == 0L`

#### H-3: Phase 44 SQL 注入防护矛盾
**问题**: 约束说禁止拼接,但代码示例直接拼接

**建议**: 使用 PreparedStatement 参数化查询

#### H-5: Phase 34 缺少 OutboxEventNotificationListener
**问题**: 架构图有但 scope 列表缺失

**修复**: 已在 C-2 中一并修复 ✅

#### H-6: Phase 48/49 HMAC 实现错误
**问题**: 描述的是字符串拼接哈希,不是真正的 HMAC

**建议**: 改为 `HMAC-SHA256(key=secret_key, data=app_key+"\n"+timestamp+"\n"+nonce+"\n"+body_hash)`

### 中等问题

#### M-1: Phase 38 CSS 注入风险
**建议**: 添加 CSS 属性白名单限制

#### M-2: Phase 35 LoggingFilter 时序问题
**建议**: 明确 filter 执行顺序

#### M-3: Phase 36 Prometheus 指标重复
**建议**: 使用 Actuator 自带指标

#### M-4: Phase 50 变量占位符冲突
**建议**: 改用 {{variable_name}} (Mustache 风格)

#### M-6: Phase 53 引用错误的 ADR
**建议**: 创建 ADR-0009-workflow-visibility.md

### 质量退化问题 (Phase 46-53)

所有 Phase 46-53 缺少:
- scope: YAML frontmatter
- 详细 DTO/VO 字段契约
- 测试契约引用
- 核心组件契约 (代码签名)
- 完整审计字段列表 (展开 "+ 7 审计字段")
- 前端文件路径

---

## 修复统计

| 级别 | 总数 | 已修复 | 待修复 |
|------|------|--------|--------|
| 🔴 CRITICAL | 6 | 5 | 1 |
| 🟠 高危 | 6 | 1 | 5 |
| 🟡 中等 | 6 | 1 | 5 |
| 🔵 质量退化 | 8 phases | 0 | 8 |

**总体进度**: 7/26 (27%)

---

## 下一步建议

1. **优先**: 修复 C-5 (Phase 44 DAG + PostgreSQL 兼容性)
2. **高优先**: 修复 H-1 到 H-6 (高危问题)
3. **中优先**: 修复 M-1 到 M-6 (中等问题)
4. **低优先**: 补全 Phase 46-53 的完整结构

**预计工作量**:
- CRITICAL + 高危: 2-3 小时
- 中等问题: 1-2 小时
- 质量补全: 4-6 小时

**总计**: 7-11 小时