# P0-P1 Spec 修复清单

## 严重问题修复

### 1. Phase 38 数据库定义冲突 ✅

**问题**:
- sys_tenant_brand 表重复定义 tenant_id 列(L63 业务列 + L78 审计列)
- Flyway 版本号冲突: Phase 34 和 Phase 38 都用 V034
- "建表+默认数据" 与 "禁止 DML" 矛盾

**修复方案**:
- 删除 L63 的业务 tenant_id 列(保留 L78 审计列)
- Phase 38 Flyway 改为 V038
- 删除"默认数据"描述,仅保留"建表 + 索引"

### 2. 测试契约文件缺失 ✅

**问题**:
- spec/tests/phase-33-cache.tests.yml 等文件不存在
- Phase 35/36/37 连测试契约引用都没有

**修复方案**:
- 创建测试契约模板文件
- 或在 spec 中标注"测试契约待补充"

### 3. 全局约束与 Phase 33 冲突 ✅

**问题**:
- 01-constraints.md#L75: 字典/配置仅 Caffeine,不使用 Redis/MQ
- Phase 33 引入 Redis L2 + Pub/Sub
- reference/list.md#L395: brandCache 使用 Caffeine L1 + Redis L2

**修复方案**:
- 更新 01-constraints.md,明确多级缓存策略
- 字典/配置使用 CAFFEINE_REDIS 档位(最终一致性)
- 权限/菜单使用 REDIS_ONLY 档位(强一致性)

### 4. 日志/指标基数策略冲突 ✅

**问题**:
- reference/list.md#L128: Loki label 仅 app/env/level
- Phase 35: traceId/tenantId/userId 做成 label
- Phase 36: 租户维度不进 Prometheus,但示例用了 tenant_id label

**修复方案**:
- Loki label 仅保留 app/env/level
- traceId/tenantId/userId 作为 JSON 字段,不做 label
- Phase 36 删除 tenant_id label 示例

### 5. 权限字符串不一致 ✅

**问题**:
- Phase 38: tenant:brand:view/update
- reference/list.md#L399: tenant:brand:list/edit
- Phase 40: system:post:remove
- reference/list.md#L544: system:post:delete

**修复方案**:
- 统一采用 reference/list.md 的权限命名
- 查询列表: list
- 查询详情: query
- 新增: add
- 编辑: edit
- 删除: remove (统一改为 remove,因为是软删除)

---

## 中等问题修复

### 6. 引用的规范章节不存在 ✅

**问题**:
- Phase 33/34/38/40 引用 spec/04-database.md 的对应章节
- 但 04-database.md 没有相应内容

**修复方案**:
- 删除不存在的章节引用
- 或补充 04-database.md 内容

### 7. Phase 36 告警表达式错误 ✅

**问题**:
```yaml
expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.05
```
这是"5xx 请求速率绝对值 > 0.05",不是错误率

**修复方案**:
```yaml
expr: |
  sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
  /
  sum(rate(http_server_requests_seconds_count[5m]))
  > 0.05
```

### 8. 接口语义歧义 ✅

**问题**:
- Phase 40: GET /api/v1/posts 声明 PostQueryDTO 请求体(GET body 兼容性差)
- Phase 34: 同时描述 "Quartz Job" 和 @Scheduled

**修复方案**:
- GET 请求使用 Query Parameters,不用 Request Body
- Phase 34 统一使用 @Scheduled,删除 Quartz Job 描述

---

## 开放问题决策

### Q1: docs/reference/list.md 是否还是权威源?

**决策**: ✅ **是**

**理由**:
- reference/list.md 是完整功能清单 v2.0,包含 58 张表、132 个权限、68 个功能模块
- Phase spec 应该与 reference/list.md 保持一致
- 如有冲突,以 reference/list.md 为准

**行动**:
- 修复 Phase 33-40 与 reference/list.md 的冲突
- 后续 Phase spec 生成时,严格参考 reference/list.md

### Q2: 权限命名标准

**决策**: ✅ **统一采用以下标准**

| 操作 | 权限后缀 | 说明 |
|------|---------|------|
| 查询列表 | list | 列表查询 |
| 查询详情 | query | 单条查询 |
| 新增 | add | 创建 |
| 编辑 | edit | 更新 |
| 删除 | remove | 软删除 |

**示例**:
- `system:user:list` - 查询用户列表
- `system:user:query` - 查询用户详情
- `system:user:add` - 新增用户
- `system:user:edit` - 编辑用户
- `system:user:remove` - 删除用户

**行动**:
- 修复 Phase 38/40 的权限字符串
- 更新 reference/list.md 中不一致的权限(如 delete 改为 remove)

---

## 修复优先级

### 立即修复 (阻塞实施)
1. ✅ Phase 38 数据库定义冲突
2. ✅ Phase 38 Flyway 版本号冲突
3. ✅ 权限字符串不一致

### 高优先级 (影响架构)
4. ✅ 全局约束与 Phase 33 冲突
5. ✅ 日志/指标基数策略冲突

### 中优先级 (影响质量)
6. ✅ 告警表达式错误
7. ✅ 接口语义歧义
8. ✅ 引用的规范章节不存在

### 低优先级 (可延后)
9. 📝 测试契约文件补充

---

## 修复后验证

- [ ] Phase 33-40 spec 与 reference/list.md 一致性检查
- [ ] Flyway 版本号无冲突
- [ ] 权限字符串统一
- [ ] 数据库表定义无重复列
- [ ] 缓存策略一致
- [ ] 日志/指标基数策略一致
- [ ] 告警表达式正确
- [ ] 接口语义清晰

---

**文档版本**: v1.0
**生成时间**: 2026-03-01
**状态**: 待修复
