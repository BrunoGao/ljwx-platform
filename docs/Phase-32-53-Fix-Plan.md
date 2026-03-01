# Phase 32-53 深度评审修复计划

## 修复状态追踪

### 🔴 CRITICAL 问题

- [x] **C-1: Flyway 版本号乱序** ✅ FIXED
  - 修复: 重新分配版本号 V035-V042
  - Phase 35-37: V035-V037 (预留给其他 Phase)
  - Phase 38: V038-V039 (保持不变)
  - Phase 40: V040-V041 (从 V035-V036 改为 V040-V041)
  - Phase 41: V042 (从 V037 改为 V042)

- [x] **C-2: Phase 34 DAG 违规** ✅ FIXED
  - 修复: 将 OutboxEventPoller 和 OutboxEventNotificationListener 移至 app 模块
  - 影响文件: Phase 34 spec

- [x] **C-3: Phase 41 DAG 违规** ✅ FIXED
  - 修复: 将 TenantLifecycleFilter 移至 app 模块
  - 影响文件: Phase 41 spec

- [x] **C-4: Phase 43 DAG 违规** ✅ FIXED
  - 修复: 将 TenantDomainFilter 移至 app 模块
  - 影响文件: Phase 43 spec

- [ ] **C-5: Phase 44 DAG 违规 + PostgreSQL 不兼容** ⚠️ NEEDS DESIGN CHANGE
  - 问题 1: DataScopeInterceptor 在 data 依赖 security
  - 问题 2: find_in_set() 是 MySQL 函数
  - 修复方案:
    - 通过 ThreadLocal 传递用户信息
    - 使用 PostgreSQL 兼容的 SQL
  - 影响文件: Phase 44 spec

- [ ] **C-6: Phase 45 DAG 违规** - TaskExecutionLogger 在 core 依赖 app
  - 修复方案: 移至 app 模块
  - 影响文件: Phase 45 spec

### 🟠 高危问题

- [ ] **H-1: Phase 33 命名冲突** - @Cacheable 与 Spring 冲突
  - 修复方案: 重命名为 @LjwxCacheable
  - 影响文件: Phase 33 spec

- [ ] **H-2: Phase 42 Long 比较 bug**
  - 问题: `userTenantId == 0` 应该用 equals()
  - 修复方案: 改为 `Long.valueOf(0).equals(userTenantId)`
  - 影响文件: Phase 42 spec

- [ ] **H-3: Phase 44 SQL 注入防护矛盾**
  - 问题: 约束说禁止拼接,但代码示例直接拼接
  - 修复方案: 使用 PreparedStatement 参数化
  - 影响文件: Phase 44 spec

- [ ] **H-4: Phase 43 缺少 verify_token 字段**
  - 问题: 代码使用了 getVerifyToken() 但表结构没有此列
  - 修复方案: 在表结构中添加 verify_token 列
  - 影响文件: Phase 43 spec

- [ ] **H-5: Phase 34 缺少 OutboxEventNotificationListener**
  - 问题: 架构图有但 scope 列表缺失
  - 修复方案: 添加到 scope 列表
  - 影响文件: Phase 34 spec

- [ ] **H-6: Phase 48/49 HMAC 实现错误**
  - 问题: 描述的是字符串拼接哈希,不是真正的 HMAC
  - 修复方案: 改为 HMAC-SHA256(key=secret_key, data=...)
  - 影响文件: Phase 48, 49 spec

### 🟡 中等问题

- [ ] **M-1: Phase 38 CSS 注入风险**
  - 修复方案: 添加 CSS 属性白名单限制
  - 影响文件: Phase 38 spec

- [ ] **M-2: Phase 35 LoggingFilter 时序问题**
  - 修复方案: 明确 filter 执行顺序
  - 影响文件: Phase 35 spec

- [ ] **M-3: Phase 36 Prometheus 指标重复**
  - 修复方案: 使用 Actuator 自带指标
  - 影响文件: Phase 36 spec

- [ ] **M-4: Phase 50 变量占位符冲突**
  - 修复方案: 改用 {{variable_name}} (Mustache 风格)
  - 影响文件: Phase 50 spec

- [ ] **M-5: Phase 43 引用不存在的文件**
  - 修复方案: 确认 constraints.yml 存在或移除引用
  - 影响文件: Phase 43 spec

- [ ] **M-6: Phase 53 引用错误的 ADR**
  - 修复方案: 创建 ADR-0009-workflow-visibility.md
  - 影响文件: Phase 53 spec, 新建 ADR

### 🔵 质量退化问题 (Phase 46-53)

所有 Phase 46-53 缺少:
- [ ] scope: YAML frontmatter
- [ ] 详细 DTO/VO 字段契约
- [ ] 测试契约引用
- [ ] 核心组件契约 (代码签名)
- [ ] 完整审计字段列表 (展开 "+ 7 审计字段")
- [ ] 前端文件路径

## 修复优先级

1. ✅ C-1: Flyway 版本号 (已完成)
2. C-2 到 C-6: DAG 违规 (阻塞性)
3. H-1 到 H-6: 高危问题
4. M-1 到 M-6: 中等问题
5. Phase 46-53 质量补全

## 下一步行动

1. 修复 Phase 34 spec (C-2, H-5)
2. 修复 Phase 41 spec (C-3)
3. 修复 Phase 43 spec (C-4, H-4, M-5)
4. 修复 Phase 44 spec (C-5, H-3)
5. 修复 Phase 45 spec (C-6)
6. 补全 Phase 46-53 的完整结构
