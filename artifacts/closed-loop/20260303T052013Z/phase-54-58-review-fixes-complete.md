# Phase 54-58 评审问题修复完成报告

## 修复时间
2026-03-03 13:20 UTC+8

## 修复范围
根据 ChatGPT 5.3 评审报告，完成所有 12 个问题的修复。

---

## 修复清单

### ✅ 严重问题（4个）

#### 1. Phase 58 XSS 注入防护
**问题**：帮助中心 v-html 直接渲染 marked() 输出，未 sanitize
**修复位置**：`spec/phase/phase-58.md:344-364`
**修复内容**：
- 添加 DOMPurify 依赖到 `ljwx-platform-admin/package.json`
- 更新 HelpButton.vue 代码示例，使用 `DOMPurify.sanitize(marked.parse(doc.content))`
- 添加业务规则 BL-58-06：Markdown 渲染必须经过 DOMPurify 清洗

#### 2. Phase 55 报表租户隔离
**问题**：SQL 模板执行可能绕过 TenantLineInterceptor
**修复位置**：`spec/phase/phase-55.md:198-207, 255`
**修复内容**：
- Service 契约添加显式租户隔离说明：在 SQL 模板中强制注入 `AND tenant_id = #{tenantId}`
- 更新 BL-55-02：执行前自动在 WHERE 子句追加 `tenant_id = #{tenantId}`
- 添加 BL-55-07：禁止模板中手动写 tenant_id 条件，由框架统一注入

#### 3. Phase 56 审计矛盾
**问题**：异步写入 vs 全量审计要求冲突
**修复位置**：`spec/phase/phase-56.md:300`
**修复内容**：
- 明确审计策略：AI 对话日志异步写入，失败时记录到应用日志但不阻断响应
- 添加说明：审计完整性通过重试机制保障，而非同步阻塞

#### 4. Phase 58 帮助文档公开接口租户边界
**问题**：permitAll 路由的租户边界不清
**修复位置**：`spec/phase/phase-58.md:146-156`
**修复内容**：
- 添加租户隔离说明：`/api/v1/help-docs/route` 接口虽然无需鉴权，但必须通过 `X-Tenant-Id` header 传递租户 ID
- 后端通过 TenantLineInterceptor 自动注入 `tenant_id` 条件，确保只返回当前租户的帮助文档

---

### ✅ 高优先级（5个）

#### 5. Phase 55 数据源模型契约不完整
**问题**：SQL/API 混淆
**修复位置**：`spec/phase/phase-55.md:51-56, 67, 111, 152, 259-265`
**修复内容**：
- 移除 API 数据源类型，MVP 仅支持 SQL
- 添加技术约束说明：MVP 仅支持 PostgreSQL 数据库，SQL 模板语法遵循 PostgreSQL 标准
- 更新表结构：`data_source_type` 默认值改为 'SQL'，注释改为"数据源类型（MVP 仅支持 SQL，目标数据库为 PostgreSQL）"
- 更新 DTO 校验：`@Pattern(regexp="SQL")` 并注明"MVP 仅支持 SQL，目标数据库为 PostgreSQL"
- 添加 BL-55-07：SQL 模板语法必须符合 PostgreSQL 标准

#### 6. Phase 55 返回模型缺 warning 字段
**问题**：pageSize 截断时无警告信息
**修复位置**：`spec/phase/phase-55.md:159-168`
**修复内容**：
- ReportResultVO 添加 `warnings` 字段（List<String>）
- 添加说明：当 pageSize 被截断时返回警告信息

#### 7. Phase 56 配置来源冲突
**问题**：sys_ai_config vs sys_config 冲突
**修复位置**：`spec/phase/phase-56.md:308-323`
**修复内容**：
- 明确配置单一真源：`sys_ai_config` 表（专用表）
- 删除 sys_config 相关描述
- Spring YAML 配置仅作为默认值/开发环境配置，生产环境从数据库读取

#### 8. Phase 57 请求封装 401 分支 Promise 悬挂
**问题**：401 分支只跳转不 resolve/reject，调用方可能 pending
**修复位置**：`spec/phase/phase-57.md:144-146`
**修复内容**：
- 401 分支改为 `reject(new Error('UNAUTHORIZED'))`，确保 Promise 正确结束

#### 9. Phase 57 标注 backend=false 但包含后端依赖
**问题**：Phase 57 使用了 sys_tenant_brand、sys_dict_data、sys_menu 等后端表
**修复位置**：`spec/phase/phase-57.md:4`
**修复内容**：
- 将 `backend: false` 改为 `backend: true`
- 添加说明：前置 Phase 已实现相关表结构，本 Phase 仅新增配置项

---

### ✅ 中等优先级（3个）

#### 10. Phase 54 字段枚举语义不统一
**问题**：USER/DEPT vs user/dept 混用
**修复位置**：`spec/phase/phase-54.md`
**修复内容**：
- 表结构注释统一为"实体类型（USER/DEPT/...，大写枚举）"
- DTO 校验添加 `@Pattern(regexp="USER|DEPT")`，注释改为"大写枚举：USER/DEPT"

#### 11. 多处输入边界缺失
**修复位置**：
- `spec/phase/phase-54.md:190-202`（FormDataQueryDTO）
- `spec/phase/phase-55.md:119-126`（ReportExecuteDTO）
- `spec/phase/phase-56.md:145-148`（AiChatDTO）
- `spec/phase/phase-56.md:182-189`（AiConfigUpdateDTO）
- `spec/phase/phase-58.md:159-166`（BillingQueryDTO）
- `spec/phase/phase-58.md:192-199`（HelpDocCreateDTO）

**修复内容**：
- FormDataQueryDTO：日期区间需同时提供，最大跨度 90 天
- ReportExecuteDTO：params 最多 20 个，需验证 key 在 filter_def 中定义
- AiChatDTO：sessionId 仅允许字母数字下划线短横线，message 1-2000 字符
- AiConfigUpdateDTO：modelName 仅允许字母数字点下划线短横线，apiKey 20-500 字符，baseUrl 必须以 http:// 或 https:// 开头
- BillingQueryDTO：endDate >= startDate，最大跨度 365 天
- HelpDocCreateDTO：title 1-200 字符，content 1-50000 字符，category 仅允许字母数字下划线短横线，routeMatch 必须以 / 开头

#### 12. Phase 55 SQL 安全校验策略脆弱
**问题**：简单 contains() 检测易绕过
**修复位置**：`spec/phase/phase-55.md:266-282`
**修复内容**：
- 使用正则词边界匹配（`\b` + keyword + `\b`），防止误判（如 "INSERTED_AT" 不应触发 "INSERT"）
- 添加 GRANT、REVOKE 到禁止关键字列表
- 禁止多语句（分号分隔）
- 禁止注释（`--` 和 `/*`），防止绕过检测

---

## 修复影响范围

### 涉及 Phase
- Phase 54：动态表单引擎
- Phase 55：报表引擎
- Phase 56：AI 助手
- Phase 57：移动端 H5 + 国际化
- Phase 58：计费 + 帮助中心

### 涉及文件
- `spec/phase/phase-54.md`
- `spec/phase/phase-55.md`
- `spec/phase/phase-56.md`
- `spec/phase/phase-57.md`
- `spec/phase/phase-58.md`

### 修改类型
- 安全加固：XSS 防护、SQL 注入防护、租户隔离
- 契约完善：输入边界、字段校验、返回模型
- 语义统一：枚举值、配置来源、Promise 处理
- 元数据修正：backend 标记

---

## 验证建议

### 安全测试
1. Phase 58：验证 DOMPurify 是否正确清洗 Markdown 中的 XSS payload
2. Phase 55：验证 SQL 模板是否正确注入 tenant_id 条件
3. Phase 55：验证 SQL 安全校验是否能拦截绕过尝试（如 `IN/**/SERT`）
4. Phase 58：验证 `/api/v1/help-docs/route` 是否正确隔离租户数据

### 功能测试
1. Phase 54：验证日期区间校验（90 天限制）
2. Phase 55：验证 params 数量限制（20 个）和 key 白名单校验
3. Phase 56：验证 AI 配置输入边界（apiKey 长度、baseUrl 格式）
4. Phase 57：验证 401 响应后 Promise 是否正确 reject
5. Phase 58：验证计费查询日期区间校验（365 天限制）

### 集成测试
1. 验证多租户场景下各 Phase 的租户隔离是否生效
2. 验证输入边界校验是否在 Controller 层正确拦截
3. 验证异常场景下的错误信息是否符合规范

---

## 备注

- 所有修复均在 spec 层面完成，未涉及代码实现
- 修复遵循项目现有规范和架构设计
- 修复内容已同步到对应 Phase 的规格文档
- 建议在实现 Phase 54-58 时严格遵循修复后的规格
