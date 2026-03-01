# P0-P1 Spec 修复报告

## 修复完成情况

### ✅ 已修复的严重问题

#### 1. Phase 38 数据库定义冲突
- **问题**: sys_tenant_brand 表重复定义 tenant_id 列
- **修复**: 删除 L63 的业务 tenant_id 列,仅保留审计字段中的 tenant_id
- **验证**: ✅ 表定义无重复列

#### 2. Phase 38 Flyway 版本号冲突
- **问题**: Phase 34 和 Phase 38 都用 V034
- **修复**: Phase 38 改为 V038
- **验证**: ✅ Flyway 版本号无冲突

#### 3. Phase 38 权限字符串不一致
- **问题**: 使用 view/update,与 reference/list.md 不一致
- **修复**: 改为 list/edit
- **验证**: ✅ 与 reference/list.md 一致

#### 4. Phase 40 接口语义歧义
- **问题**: GET /api/v1/posts 声明 PostQueryDTO 请求体
- **修复**: 改为 Query Parameters
- **验证**: ✅ 接口语义清晰

#### 5. Phase 35 Loki label 高基数问题
- **问题**: traceId/tenantId/userId 做成 label
- **修复**: 仅保留 app/env/level label,其他作为 JSON 字段
- **验证**: ✅ 符合低基数原则

#### 6. Phase 36 租户指标高基数问题
- **问题**: 示例使用 tenant_id label
- **修复**: 删除租户维度 Prometheus 指标,改为 Loki 日志查询
- **验证**: ✅ 符合低基数原则

#### 7. Phase 36 告警表达式错误
- **问题**: 使用绝对值而非错误率
- **修复**: 改为正确的错误率计算公式
- **验证**: ✅ 告警表达式正确

#### 8. Phase 34 调度描述不一致
- **问题**: 同时描述 "Quartz Job" 和 @Scheduled
- **修复**: 统一使用 @Scheduled
- **验证**: ✅ 描述一致

---

## 📝 待补充的问题

### 1. 测试契约文件缺失

**问题**: spec/tests/phase-33-cache.tests.yml 等文件不存在

**建议方案**:
- 方案 A: 创建测试契约模板文件
- 方案 B: 在 spec 中标注"测试契约待补充"
- 方案 C: 在实施阶段再补充测试契约

**推荐**: 方案 B (先标注,实施时补充)

### 2. 引用的规范章节不存在

**问题**: Phase 33/34/38/40 引用 spec/04-database.md 的对应章节,但不存在

**建议方案**:
- 方案 A: 删除不存在的章节引用
- 方案 B: 补充 04-database.md 内容
- 方案 C: 改为引用 docs/reference/list.md

**推荐**: 方案 A (删除不存在的引用)

### 3. 全局约束与 Phase 33 冲突

**问题**: 01-constraints.md#L75 说字典/配置仅 Caffeine,不使用 Redis/MQ

**建议方案**:
- 更新 01-constraints.md,明确多级缓存策略
- 字典/配置使用 CAFFEINE_REDIS 档位(最终一致性)
- 权限/菜单使用 REDIS_ONLY 档位(强一致性)

**推荐**: 更新 01-constraints.md

---

## 决策确认

### Q1: docs/reference/list.md 是否还是权威源?

**决策**: ✅ **是**

**理由**:
- reference/list.md 是完整功能清单 v2.0
- 包含 58 张表、132 个权限、68 个功能模块
- Phase spec 应该与 reference/list.md 保持一致

**行动**:
- ✅ 已修复 Phase 38/40 与 reference/list.md 的冲突
- 📝 后续 Phase spec 生成时,严格参考 reference/list.md

### Q2: 权限命名标准

**决策**: ✅ **统一采用以下标准**

| 操作 | 权限后缀 | HTTP 方法 | 说明 |
|------|---------|-----------|------|
| 查询列表 | list | GET | 列表查询 |
| 查询详情 | query | GET | 单条查询 |
| 新增 | add | POST | 创建 |
| 编辑 | edit | PUT | 更新 |
| 删除 | remove | DELETE | 软删除 |

**示例**:
- `system:user:list` - 查询用户列表
- `system:user:query` - 查询用户详情
- `system:user:add` - 新增用户
- `system:user:edit` - 编辑用户
- `system:user:remove` - 删除用户

**行动**:
- ✅ 已修复 Phase 38/40 的权限字符串
- 📝 需要更新 reference/list.md 中不一致的权限(如 delete 改为 remove)

---

## 修复验证清单

- [x] Phase 33-40 spec 与 reference/list.md 权限一致性
- [x] Flyway 版本号无冲突
- [x] 权限字符串统一为 list/query/add/edit/remove
- [x] 数据库表定义无重复列
- [x] 日志/指标基数策略符合低基数原则
- [x] 告警表达式正确
- [x] 接口语义清晰(GET 使用 Query Parameters)
- [x] 调度描述一致(@Scheduled)
- [ ] 测试契约文件补充(待实施阶段)
- [ ] 引用的规范章节清理(待决策)
- [ ] 全局约束更新(待决策)

---

## 下一步行动

### 立即行动
1. ✅ 已完成所有严重问题修复
2. ✅ 已完成权限命名标准统一
3. ✅ 已完成 Flyway 版本号冲突修复

### 待决策
1. 📝 测试契约文件补充方案
2. 📝 引用的规范章节处理方案
3. 📝 全局约束更新方案

### 后续工作
1. 📝 生成 Phase 41-53 的 P1 剩余功能 spec
2. 📝 生成 Phase 54-67 的 P2 扩展功能 spec
3. 📝 生成 Phase 68 的 Final Gate spec

---

## 修复影响评估

### 影响范围
- ✅ Phase 33-40 spec 文档
- ✅ docs/P0-P1-Spec-Index.md
- ✅ docs/P0-P1-Spec-Fix-Checklist.md

### 无影响范围
- ✅ 已实施的 Phase 0-32 代码
- ✅ 数据库迁移文件 V001-V031
- ✅ 前端代码

### 风险评估
- ✅ 无破坏性变更
- ✅ 无数据迁移风险
- ✅ 无向后兼容性问题

---

**文档版本**: v1.0
**修复时间**: 2026-03-01
**状态**: ✅ 严重问题已全部修复,待决策问题需进一步讨论
