# Phase 54-58 评审问题修复记录

## 评审来源
ChatGPT 5.3 对 Phase 54-58 的评审意见

## 修复状态

### 严重问题（4个）

#### 1. ✅ 前端 XSS 注入 - v-html 未 sanitize
**位置**: phase-58.md:344、phase-58.md:364
**问题**: HelpButton.vue 直接 v-html 渲染 marked() 输出，未使用 DOMPurify
**修复**: 在 phase-58.md 中添加 DOMPurify 依赖和使用说明

#### 2. ✅ 报表租户隔离机制风险
**位置**: phase-55.md:51、phase-55.md:255
**问题**: 报表执行使用原生 SQL，TenantLineInterceptor 可能不生效
**修复**: 在 phase-55.md 中明确说明报表执行的租户隔离策略

#### 3. ✅ Phase 56 审计要求矛盾
**位置**: phase-56.md:300、phase-56.md:364
**问题**: 一处写"异步写入"，另一处写"全量审计"
**修复**: 统一为"同步写入，失败时记录错误但不阻断响应"

#### 4. ✅ 帮助文档公开接口租户边界不清
**位置**: phase-58.md:100、phase-58.md:151、phase-58.md:404
**修复**: 明确 /help-docs/route 的租户上下文获取策略

### 高优先级问题（5个）

#### 5. ✅ Phase 55 数据源模型契约不完整
**位置**: phase-55.md:54、phase-55.md:111、phase-55.md:198
**问题**: 声明支持 API 类型但缺少执行契约
**修复**: 移除 API 类型支持，MVP 仅支持 SQL 类型

#### 6. ✅ Phase 55 返回模型与业务规则不一致
**位置**: phase-55.md:159、phase-55.md:253
**问题**: BL 要求返回 warning，但 VO 未定义该字段
**修复**: 在 ReportResultVO 中添加 warnings 字段

#### 7. ✅ Phase 56 配置来源定义冲突
**位置**: phase-56.md:69、phase-56.md:308、phase-56.md:323
**问题**: sys_ai_config 表 vs sys_config vs 环境变量
**修复**: 统一为 sys_ai_config 表作为唯一配置源

#### 8. ✅ Phase 57 请求封装 401 分支 Promise 悬挂
**位置**: phase-57.md:144
**问题**: 401 分支只跳转不 resolve/reject
**修复**: 添加 reject 调用

#### 9. ✅ Phase 57 标注 backend=false 但包含后端依赖
**位置**: phase-57.md:5、phase-57.md:213、phase-57.md:230
**问题**: 需要后端字段支持但标记为纯前端
**修复**: 添加说明，这些字段在前置 Phase 中已实现

### 中等优先级问题（3个）

#### 10. ✅ Phase 54 字段枚举语义不统一
**位置**: phase-54.md:127、phase-54.md:246
**问题**: entity_type 大小写不一致
**修复**: 统一为大写枚举值

#### 11. ✅ 多处输入边界缺失
**位置**: phase-54.md:192、phase-58.md:162
**问题**: 日期区间、JSONB 大小未限制
**修复**: 添加输入边界校验规则

#### 12. ✅ Phase 55 SQL 安全校验策略脆弱
**位置**: phase-55.md:261
**问题**: 仅靠关键字黑名单
**修复**: 增强 SQL 校验策略说明
