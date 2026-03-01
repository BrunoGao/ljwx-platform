

Let me think carefully about what's needed. The user wants a complete, revised feature inventory that incorporates all the review feedback from ChatGPT 5.2 Pro. This needs to be a comprehensive, authoritative document that reflects all the decisions made in the previous response. Let me compile this systematically.

This is a massive document that needs to integrate:
1. The original 14-domain feature list
2. The 8 expansion directions
3. All review feedback corrections (Redis L2, Prometheus label fix, Outbox pattern, HMAC security, workflow visibility model, dept leader_user_id, DoD, 5-layer architecture)
4. The revised phase plan

Let me structure this properly.

# 灵境万象（LJWX）多租户 SaaS 基座平台 —— 评审修订版功能清单 v2.0

---

## 〇、修订说明

本版基于 ChatGPT 5.2 Pro 评审意见全量采纳后重建，与 v1.0 的核心差异如下：

| 变更项 | v1.0 | v2.0 |
|--------|------|------|
| 架构分层 | 14 个平铺功能域 | **5 层 + L0 横切**分层架构 |
| 缓存方案 | 全量 Caffeine | **Caffeine L1 + Redis L2 + Pub/Sub 广播** |
| 事件一致性 | ApplicationEventPublisher 仅内存 | **Outbox 表 + 异步投递**，保证"写库+发消息"原子性 |
| 租户指标 | Prometheus label 含 tenantId | **Prometheus 低基数 + Loki 字段级 + 落库统计**三层策略 |
| 开放平台安全 | HMAC 基础签名 | **HMAC + nonce 防重放(Redis) + 时钟校验 + 密钥轮换** |
| 工作流权限 | 未定义 | **6 级可见性模型 + Outbox 集成** |
| 部门负责人 | leader VARCHAR | **leader_user_id BIGINT + sys_dept_leader 关联表** |
| 数据脱敏 | P1 未排期 | **Phase 29 前置**，先于开放平台 |
| 表单检索 | 未定义 | **元字段优先 + Generated Column 增强 + GIN 兜底** |
| 交付验收 | 无标准 | **8 项 DoD 统一模板** |
| 基础设施 | 无 Redis | **Redis Sentinel（1 主 2 从）** |
| 数据库表 | 39 张 | **58 张** |
| 权限字符串 | ~80 个 | **~132 个** |
| Phase | 1-27 + 28-35 | **1-35（Phase 5/20/22 内容修订）** |

---

## 一、分层架构总览

```
┌──────────────────────────────────────────────────────────────┐
│ L5  业务扩展层                                                │
│   流程引擎 │ 自定义表单 │ 报表引擎 │ AI 智能助手              │
├──────────────────────────────────────────────────────────────┤
│ L4  开放与集成层                                              │
│   开放 API(HMAC) │ Webhook │ 消息中台 │ 数据同步              │
├──────────────────────────────────────────────────────────────┤
│ L3  基础能力层                                                │
│   字典 │ 参数 │ 文件 │ 公告 │ 调度 │ 导入导出 │ 代码生成      │
│   数据大屏 │ 前端应用                                         │
├──────────────────────────────────────────────────────────────┤
│ L2  身份与权限层                                              │
│   用户 │ 角色 │ 菜单 │ 部门 │ 岗位 │ 数据范围 │ 认证(JWT)     │
│   在线用户 │ 个人中心                                         │
├──────────────────────────────────────────────────────────────┤
│ L1  平台治理层                                                │
│   租户 │ 套餐 │ 品牌 │ 域名 │ 计量计费 │ 运营看板 │ 帮助中心  │
├══════════════════════════════════════════════════════════════┤
│ L0  横切基础设施（贯穿所有层）                                 │
│   缓存(Caffeine L1 + Redis L2 + Pub/Sub)                     │
│   可观测(结构化日志 + Prometheus 指标 + OpenTelemetry 追踪)    │
│   审计(操作日志 + 登录日志 + 数据变更审计)                     │
│   安全(XSS + 限流 + 幂等 + 脱敏 + 加密 + Token 黑名单)       │
│   事件驱动(ApplicationEventPublisher + Outbox 表)             │
│   多端适配 │ 国际化(i18n)                                     │
└──────────────────────────────────────────────────────────────┘
```

编号规则：`L{层}-D{域序号}-F{功能序号}`，如 `L2-D01-F03` = 身份权限层 → 用户域 → 第 3 个功能。

---

## 二、L0 横切基础设施（贯穿所有层）

### L0-D01 缓存体系

#### L0-D01-F01 多级缓存管理器

| 项目 | 内容 |
|------|------|
| 功能 | Caffeine L1 + Redis L2 双层缓存，变更时通过 Redis Pub/Sub 广播失效 |
| 核心组件 | `MultiLevelCacheManager`、`RedisCacheEvictPublisher`、`RedisCacheEvictSubscriber`、`CaffeineCacheRegistry` |
| 读取路径 | Caffeine L1（TTL 短）→ Redis L2（TTL 长）→ DB |
| 写入/变更 | 更新 DB → 删除 Redis key → Pub/Sub 发送 `cache:evict:{cacheName}:{cacheKey}` → 所有 Pod 清除本地 Caffeine |
| 最坏不一致窗口 | Pub/Sub 延迟 <10ms；消息丢失时降级为 Caffeine TTL 自然过期（2min） |
| 所属 Phase | **Phase 20** |

#### L0-D01-F02 缓存分档策略

**第一档：强一致性 —— Redis Only（不经过 Caffeine）**

| 缓存名称 | Key 模式 | TTL | 存储结构 | 用途 |
|-----------|----------|-----|----------|------|
| tokenBlacklist | `blacklist:{jti}` | 与 Token 过期对齐 | Redis SET | 强制下线 |
| onlineUserCache | `online:{tokenId}` | 与 Token 过期对齐 | Redis HASH | 在线用户 |
| openAppNonce | `open:nonce:{appKey}:{nonce}` | 300s | Redis SET (SETNX) | 开放 API 防重放 |

**第二档：短窗口最终一致 —— Caffeine L1 + Redis L2 + Pub/Sub 广播**

| 缓存名称 | Key 模式 | L1 TTL | L2 TTL | 最大条目 | 失效触发 |
|-----------|----------|--------|--------|----------|----------|
| permissionCache | `perms:{tenantId}:{userId}` | 2min | 10min | 5000 | 角色权限/用户角色变更 |
| userMenuCache | `menu:{tenantId}:{userId}` | 2min | 10min | 5000 | 菜单/角色菜单变更 |
| dataScopeCache | `scope:{tenantId}:{userId}` | 2min | 5min | 5000 | 角色数据范围/部门变更 |
| brandCache | `brand:{tenantId}` | 5min | 30min | 500 | 品牌配置变更 |
| domainTenantCache | `domain:{domain}` | 10min | 1h | 500 | 租户域名变更 |

**第三档：纯本地缓存 —— Caffeine Only**

| 缓存名称 | Key 模式 | TTL | 最大条目 | 失效触发 |
|-----------|----------|-----|----------|----------|
| dictCache | `dict:{dictType}` | 1h | 200 | 字典变更（手动/定时刷新） |
| configCache | `config:{configKey}` | 1h | 200 | 参数变更（手动/定时刷新） |
| allMenuCache | `menu:all` | 30min | 1 | 菜单变更 |
| userProfileCache | `profile:{userId}` | 30min | 5000 | 个人信息变更 |

### L0-D02 可观测体系（K8s 原生）

#### L0-D02-F01 结构化日志

| 项目 | 内容 |
|------|------|
| 功能 | Logback JSON Console 输出至 stdout，MDC 携带 traceId、tenantId、userId、requestUri、requestMethod |
| 核心组件 | `LogContextFilter`（从 JWT + OpenTelemetry Span 提取写入 MDC）、`ContextAwareTaskDecorator`（异步线程 MDC 传递） |
| K8s 采集 | Fluent Bit DaemonSet → Loki |
| **Loki 索引 label** | **仅 app、env、level 三个**（tenantId 作为 JSON 字段而非索引 label，避免基数爆炸） |
| 租户维度查询 | LogQL：`{app="ljwx"} \| json \| tenantId="1001" \| level="ERROR"` |
| 保留策略 | ERROR 90 天、WARN 30 天、INFO 14 天、DEBUG 默认关闭 |
| 所属 Phase | Phase 20 |

#### L0-D02-F02 指标监控（三层策略）

| 层次 | 工具 | 包含维度 | 用途 |
|------|------|----------|------|
| 实时告警层 | Prometheus + Alertmanager | **低基数 label only**：app、env、method、uri_pattern（归一化）、status、exception | 系统健康告警 |
| 日志聚合层 | Loki Recording Rules / Alerting Rules | tenantId 在 JSON 字段中，LogQL 聚合 | 租户维度异常检测（如暴力登录） |
| 精确统计层 | PostgreSQL `bill_usage_record` | tenant_id、metric_type、usage_value、record_date | 租户计量计费、运营看板 |

Prometheus 自定义指标（全部**不含** tenantId label）：

| 指标名 | 类型 | Labels | 说明 |
|--------|------|--------|------|
| `http_server_requests_seconds` | Timer | method, uri, status | Micrometer 自带 |
| `login_total` | Counter | result(success/failure) | 登录计数 |
| `file_upload_bytes_total` | Counter | — | 文件上传总量 |
| `online_users_current` | Gauge | — | 当前在线用户数 |
| `quartz_job_duration_seconds` | Timer | job_group, job_name | 任务执行耗时 |
| `caffeine_cache_hit_rate` | Gauge | cache_name | 缓存命中率 |
| `hikaricp_connections_active` | Gauge | pool | 连接池活跃数 |

K8s 采集：ServiceMonitor CRD → Prometheus Operator。探针定义：liveness（TCP）、readiness（`PlatformReadinessIndicator` 检查 DB + Redis + 缓存）、startup（60s 宽限）。

| 所属 Phase | Phase 20 |

#### L0-D02-F03 链路追踪

| 项目 | 内容 |
|------|------|
| 功能 | Micrometer Tracing → OpenTelemetry → Grafana Tempo |
| 采样策略 | 全局 10%，错误 Span 100% |
| 传播 | traceId 写入 MDC + 日志 JSON，响应头 `X-Trace-Id` |
| K8s 部署 | OpenTelemetry Collector（in-cluster）→ Tempo |
| 所属 Phase | Phase 20 |

#### L0-D02-F04 Grafana 仪表盘与告警

| 项目 | 内容 |
|------|------|
| 仪表盘 | 全局总览（RED 指标）、JVM & 基础设施、**租户视图（数据源 = PostgreSQL bill_usage_record）**、告警列表 |
| 告警规则 | PrometheusRule：高错误率、P99 延迟、DB 连接池、JVM 堆、Pod 重启循环；**Loki Alert：5min 内某租户登录失败 >50 次** |
| 通知渠道 | Critical → 钉钉 / 企微、Warning → 邮件 |
| 所属 Phase | 基础设施 Sprint（Phase 20 后） |

#### L0-D02-F05 K8s 事件采集

| 项目 | 内容 |
|------|------|
| 功能 | `kubernetes-event-exporter` 将集群事件导入 Loki；Nginx Ingress access log（含 tenant header）也由 Fluent Bit 采集 |
| 所属 Phase | 基础设施 Sprint |

### L0-D03 审计体系

#### L0-D03-F01 操作日志

| 项目 | 内容 |
|------|------|
| 功能 | `@OperationLog` 注解记录用户操作 |
| 核心表 | `sys_operation_log`（按月分区，BRIN 索引 on created_time） |
| 关键字段 | id, tenant_id, module, operation_type, method, request_url, request_params, response_result, error_msg, duration_ms, **client_ip (X-Forwarded-For)**, **user_agent**, **trace_id**, **pod_name (Downward API)**, operator_id, operator_name, created_time |
| 保留策略 | 6 个月，过期归档 |
| API | `GET /api/v1/operation-logs`, `GET /api/v1/operation-logs/{id}` |
| 权限 | `system:operlog:list`, `system:operlog:query`, `system:operlog:delete`, `system:operlog:export` |
| 所属 Phase | Phase 9 |

#### L0-D03-F02 登录日志

| 项目 | 内容 |
|------|------|
| 功能 | 记录登录成功 / 失败事件 |
| 核心表 | `sys_login_log`（按月分区） |
| 关键字段 | id, tenant_id, username, login_type(PASSWORD/SSO/SCAN), result(SUCCESS/FAILURE), client_ip, location, browser, os, **pod_name**, **node_name**, error_msg, login_time |
| 保留策略 | 6 个月 |
| 告警 | **Loki Alerting Rule**（非 Prometheus）：`count_over_time({app="ljwx"} \| json \| event="LOGIN_FAILURE" \| tenantId="$tid" [5m]) > 50` |
| API | `GET /api/v1/login-logs` |
| 权限 | `system:loginlog:list`, `system:loginlog:query`, `system:loginlog:delete`, `system:loginlog:export` |
| 所属 Phase | Phase 22 |

#### L0-D03-F03 数据变更审计

| 项目 | 内容 |
|------|------|
| 功能 | MyBatis 拦截器自动记录关键表的 INSERT/UPDATE/DELETE 前后数据快照 |
| 核心表 | `sys_data_change_log`（按月分区） |
| 关键字段 | id, tenant_id, table_name, record_id, change_type(INSERT/UPDATE/DELETE), before_data(JSONB), after_data(JSONB), **trace_id**, operator_id, created_time |
| 安全 | **表权限仅 INSERT**，不可修改、不可删除 |
| 保留策略 | 12 个月 |
| API | `GET /api/v1/data-change-logs` |
| 权限 | `system:changelog:list` |
| 所属 Phase | Phase 24 |

### L0-D04 安全防护

#### L0-D04-F01 XSS 过滤

| 项目 | 内容 |
|------|------|
| 功能 | 全局 Filter 过滤请求中的 XSS 脚本 |
| 所属 Phase | Phase 4（Web 模块即加入） |

#### L0-D04-F02 SQL 注入防护

| 项目 | 内容 |
|------|------|
| 功能 | 审计所有 `${}` 用法，确保 MyBatis 全面使用 `#{}` 预编译 |
| 所属 Phase | Phase 25（集成测试阶段代码审计） |

#### L0-D04-F03 数据脱敏

| 项目 | 内容 |
|------|------|
| 功能 | 自定义 Jackson 注解 `@DataMask(type = MaskType.PHONE/ID_CARD/BANK_CARD/EMAIL)`，序列化时自动替换为脱敏格式 |
| 脱敏规则 | 手机号 `138****5678`、身份证 `110***********1234`、银行卡 `6222************1234`、邮箱 `z**@example.com` |
| 权限控制 | 持有 `system:data:unmask` 权限的角色可查看原始数据（注解中 `@DataMask(unmaskPermission = "system:data:unmask")`） |
| **前置要求** | **必须在开放平台（Phase 29）上线之前完成** |
| 所属 Phase | **Phase 29（与开放平台同期或之前）** |

#### L0-D04-F04 接口幂等性

| 项目 | 内容 |
|------|------|
| 功能 | `@Idempotent` 注解 + Redis SETNX 令牌机制，防止关键写接口重复提交 |
| 所属 Phase | P1 |

#### L0-D04-F05 敏感数据加密

| 项目 | 内容 |
|------|------|
| 功能 | 手机号、身份证等字段 AES 加密存储，MyBatis TypeHandler 自动加解密 |
| 所属 Phase | P1 |

#### L0-D04-F06 密码策略

| 项目 | 内容 |
|------|------|
| 功能 | 最小长度（8+）、复杂度（大小写+数字+特殊字符）、历史密码检查（最近 5 次不可重复）、过期策略（可选 90 天） |
| 所属 Phase | Phase 22 |

#### L0-D04-F07 多层限流

| 项目 | 内容 |
|------|------|
| 功能 | 全局 → 租户 → 用户 → 接口四级限流，**Redis + Lua 滑动窗口算法** |
| 配额绑定 | 租户级配额关联 `sys_tenant_package.max_api_calls_per_day`；开放 API 级配额关联 `sys_open_app` + `sys_open_app_api` |
| 所属 Phase | P1 |

### L0-D05 事件驱动与 Outbox

#### L0-D05-F01 应用内事件

| 项目 | 内容 |
|------|------|
| 功能 | Spring `ApplicationEventPublisher` + `@EventListener` / `@TransactionalEventListener` |
| 事件基类 | `BaseEvent`（eventType, tenantId, operatorId, timestamp, traceId） |
| 已定义事件 | TenantCreatedEvent, UserDeletedEvent, RolePermissionChangedEvent, MenuChangedEvent, BrandConfigChangedEvent, DeptChangedEvent 等 |
| 所属 Phase | Phase 1（定义基类）、各 Phase 逐步增加具体事件 |

#### L0-D05-F02 Outbox 事件表

| 项目 | 内容 |
|------|------|
| 功能 | 保证"写库 + 发消息"原子性；与业务数据在同一事务中写入 Outbox 表，异步投递到消费端 |
| 核心表 | `sys_outbox_event` |
| 关键字段 | id, aggregate_type(WORKFLOW/USER/TENANT/...), aggregate_id, event_type, payload(JSONB), tenant_id, status(PENDING/SENT/FAILED), retry_count, created_time, sent_time |
| 投递机制 | Quartz Job 每 5 秒扫描 PENDING 事件 **+ PostgreSQL LISTEN/NOTIFY 即时触发** |
| 消费端 | 消息中台（发通知）、Webhook（推送外部系统）、操作日志（审计）、缓存失效 |
| 重试策略 | 1min → 5min → 30min → 标记 FAILED 并告警 |
| 清理策略 | SENT 保留 7 天、FAILED 保留 30 天；Quartz Job 每日凌晨清理 |
| 索引 | `idx_outbox_pending ON sys_outbox_event(status, created_time) WHERE status = 'PENDING'` |
| **适用场景** | 工作流节点推进、用户创建后发欢迎邮件、租户冻结后通知关联用户、Webhook 推送、品牌变更广播 |
| 所属 Phase | **Phase 20（基础框架）、Phase 28（正式启用消费端）** |

### L0-D06 多端适配

| 项目 | 内容 |
|------|------|
| 功能 | 移动端 H5（Vant / uni-app）聚焦高频场景：登录、待办审批、公告、个人中心、消息；PC 后台响应式断点适配；扫码登录 |
| 品牌配置扩展 | 新增 `mobile` category：启动图、移动端主色调等 |
| 所属 Phase | Phase 34 |

### L0-D07 国际化（i18n）

| 项目 | 内容 |
|------|------|
| 功能 | 后端错误码多语言、字典数据 `labels JSONB` 多语言、菜单 `names JSONB` 多语言；前端 vue-i18n 语言包；品牌配置增加 `platform.default_locale` |
| 所属 Phase | Phase 34 |

---

## 三、L1 平台治理层

### L1-D01 租户管理

#### L1-D01-F01 租户 CRUD

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_tenant` |
| 关键字段 | id, tenant_name, contact_person, contact_phone, **domain**, **subdomain**, package_id, status(NORMAL/FROZEN/DISABLED), expire_time, account_limit, 审计 7 列 |
| 索引 | `uk_tenant_domain(domain) WHERE domain IS NOT NULL AND deleted = FALSE`、`uk_tenant_subdomain(subdomain) WHERE subdomain IS NOT NULL AND deleted = FALSE` |
| API | `GET/POST/PUT/DELETE /api/v1/tenants`, `GET /api/v1/tenants/{id}` |
| 权限 | `system:tenant:list`, `system:tenant:query`, `system:tenant:add`, `system:tenant:edit`, `system:tenant:delete` |
| 所属 Phase | Phase 6（基础）、Phase 21（增强） |

#### L1-D01-F02 租户生命周期管理

| 项目 | 内容 |
|------|------|
| 功能 | 创建 → 初始化 → 激活 → 冻结 → 注销 |
| 核心组件 | `TenantInitializer`：自动生成管理员账号、默认角色、菜单、字典 |
| 冻结机制 | TenantStatusInterceptor 拦截冻结租户请求返回 403 |
| 注销机制 | 触发数据归档 + **Outbox 事件 TenantDisabledEvent** 通知关联系统 |
| API | `PUT /api/v1/tenants/{id}/status` |
| 所属 Phase | Phase 21 |

#### L1-D01-F03 超级管理员机制

| 项目 | 内容 |
|------|------|
| 功能 | tenant_id=0 的超级管理员跳过租户过滤，统一 RBAC，拥有 `system:tenant:*` 等全局权限 |
| 所属 Phase | Phase 21 |

#### L1-D01-F04 租户上下文跨线程传递

| 项目 | 内容 |
|------|------|
| 功能 | `TenantAwareTaskDecorator` 装饰所有线程池，确保 @Async、Quartz、线程池等场景 TenantContext 正确传递 |
| 所属 Phase | Phase 21 |

#### L1-D01-F05 租户域名识别

| 项目 | 内容 |
|------|------|
| 功能 | 多策略识别租户身份 |
| 核心组件 | `TenantResolverFilter`（最高优先级）|
| 解析顺序 | ① `X-Tenant-Id` 请求头 → ② 子域名匹配 → ③ 自定义域名匹配 → ④ URL 参数（仅开发环境）→ ⑤ 默认租户 |
| **开放 API 例外** | `/open/v1/` 路径的 tenant_id **必须从 sys_open_app.tenant_id 获取**，忽略请求头中的 X-Tenant-Id，防止伪造 |
| 缓存 | **domainTenantCache：Caffeine L1(10min) + Redis L2(1h)**（第二档） |
| K8s 配合 | Nginx Ingress 通配符域名 `*.ljwx.com` |
| 所属 Phase | Phase 21 |

### L1-D02 租户套餐管理

#### L1-D02-F01 套餐 CRUD

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_tenant_package` |
| 关键字段 | id, package_name, menu_ids(BIGINT[]), status, remark, max_user_count, max_role_count, max_dept_depth, max_storage_mb, **max_api_calls_per_day**, 审计列 |
| API | `GET/POST/PUT/DELETE /api/v1/tenant-packages`, `GET /api/v1/tenant-packages/{id}` |
| 权限 | `system:package:list`, `system:package:query`, `system:package:add`, `system:package:edit`, `system:package:delete` |
| 所属 Phase | Phase 23 |

### L1-D03 租户品牌配置

#### L1-D03-F01 品牌配置管理

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_tenant_brand` |
| 关键字段 | id, tenant_id(0=平台默认), brand_key, brand_value, value_type(STRING/JSON/IMAGE/COLOR), category(basic/login/layout/email/sms/**mobile**), allow_tenant_override, sort_order, 审计列 |
| 配置分类 | basic（平台名称、简称、描述、版本、ICP、版权、技术支持）、login（Logo、暗色 Logo、背景图、标语、注册入口开关）、layout（Favicon、侧边栏 Logo、主色调、顶栏色、侧边栏色、主题模式、布局模式、水印）、email（发件人、Logo、页脚）、sms（签名）、**mobile**（启动图、移动主色调） |
| 查询策略 | PostgreSQL `DISTINCT ON(brand_key)` 一次查询合并平台默认与租户覆盖 |
| 缓存 | **brandCache：Caffeine L1(5min) + Redis L2(30min)**（第二档）；platformDefault：Caffeine Only(2h) |
| API（公开） | `GET /api/v1/brand/config?tenantId=`（登录前调用，无需鉴权） |
| API（超管） | `GET/PUT /api/v1/brand/platform`, `GET/PUT /api/v1/brand/tenants/{tenantId}`, `DELETE /api/v1/brand/tenants/{tenantId}/{brandKey}`, `POST /api/v1/brand/tenants/{tenantId}/reset`, `POST /api/v1/brand/tenants/{tenantId}/logo`, `GET /api/v1/brand/keys` |
| API（租户管理员） | `GET/PUT /api/v1/tenant/brand`, `POST /api/v1/tenant/brand/logo`, `POST /api/v1/tenant/brand/reset` |
| 权限 | `system:brand:list`, `system:brand:edit`, `tenant:brand:list`, `tenant:brand:edit` |
| 变更通知 | **BrandConfigChangedEvent → Outbox → WebSocket 推送 `BRAND_UPDATED`** |
| 所属 Phase | Phase 21 |

### L1-D04 计量计费

#### L1-D04-F01 用量统计

| 项目 | 内容 |
|------|------|
| 核心表 | `bill_usage_record` |
| 关键字段 | id, tenant_id, metric_type(USER_COUNT/STORAGE_MB/API_CALLS/LOGIN_COUNT/...), usage_value, record_date |
| 数据来源 | Quartz 每日定时任务从 sys_operation_log、sys_login_log、sys_file 按 tenant_id 聚合统计 |
| **Grafana 对接** | **租户视图仪表盘数据源 = PostgreSQL（此表），非 Prometheus** |
| 超额处理 | 与 sys_tenant_package 配额对比，超额时通过消息中台通知租户管理员 |
| API | `GET /api/v1/billing/usage?tenantId=&startDate=&endDate=` |
| 权限 | `system:billing:list` |
| 所属 Phase | Phase 35 |

### L1-D05 运营看板

#### L1-D05-F01 全局运营仪表盘

| 项目 | 内容 |
|------|------|
| 功能 | 各租户 DAU/MAU、存储用量、API 调用量、功能使用热力图、即将过期租户预警 |
| 数据来源 | bill_usage_record + sys_tenant |
| 所属 Phase | Phase 35 |

### L1-D06 帮助中心

#### L1-D06-F01 帮助文档管理

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_help_doc` |
| 关键字段 | id, doc_key, title, content(Markdown), category, route_match(关联前端路由), sort_order |
| 前端集成 | 悬浮 "?" 图标按当前路由匹配帮助文档；新用户 onboarding tour（Driver.js） |
| API | `GET /api/v1/help-docs`, `GET /api/v1/help-docs/route?path=` |
| 权限 | `system:help:list`, `system:help:add`, `system:help:edit`, `system:help:delete` |
| 所属 Phase | Phase 35 |

---

## 四、L2 身份与权限层

### L2-D01 用户管理

#### L2-D01-F01 用户 CRUD

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_user` |
| 关键字段 | id, tenant_id, **dept_id**, username, password, nickname, email, phone, gender, avatar, status, **ext_fields(JSONB)**（租户级自定义字段），审计 7 列 |
| 索引策略 | 全部使用 partial index（`WHERE deleted = FALSE`）：`uk_tenant_username(tenant_id,username,deleted)` 唯一、`idx_tenant_dept_status(tenant_id,dept_id,status,deleted)` 权限、`idx_tenant_dept_created(tenant_id,dept_id,deleted,created_time DESC)` 分页、`idx_tenant_createdby(tenant_id,created_by,deleted)` SELF 范围 |
| API | `GET/POST/PUT/DELETE /api/v1/users`, `GET /api/v1/users/{id}`, `PUT /api/v1/users/{id}/status`, `PUT /api/v1/users/{id}/reset-password` |
| 权限 | `system:user:list`, `system:user:query`, `system:user:add`, `system:user:edit`, `system:user:delete`, `system:user:resetPwd`, `system:user:export`, `system:user:import` |
| 所属 Phase | Phase 6 |

#### L2-D01-F02 用户-角色关联

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_user_role`（user_id, role_id, tenant_id） |
| 关联方式 | DTO 中 roleIds 嵌套模式（用户创建 / 编辑时同步保存）+ 独立接口 `PUT /api/v1/users/{id}/roles` |
| **方案锁定** | Phase 8 前确定 → **现已确定：两种模式并存** |
| 所属 Phase | Phase 6 |

#### L2-D01-F03 用户-岗位关联

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_user_post`（user_id, post_id, tenant_id） |
| 所属 Phase | Phase 20 |

### L2-D02 角色管理

#### L2-D02-F01 角色 CRUD

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_role` |
| 关键字段 | id, tenant_id, role_name, role_code, **data_scope**(ALL/DEPT_AND_CHILD/DEPT/SELF/CUSTOM), sort_order, status, 审计列 |
| 索引 | `uk_tenant_rolecode(tenant_id,role_code) WHERE deleted = FALSE` |
| API | `GET/POST/PUT/DELETE /api/v1/roles`, `GET /api/v1/roles/{id}` |
| 权限 | `system:role:list`, `system:role:query`, `system:role:add`, `system:role:edit`, `system:role:delete` |
| 所属 Phase | Phase 6 |

#### L2-D02-F02 角色-菜单关联

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_role_menu`（role_id, menu_id, tenant_id） |
| 功能 | 为角色分配菜单 / 按钮权限；权限字符串来源于 sys_menu.permission |
| API | `PUT /api/v1/roles/{id}/menus` |
| **缓存失效** | 变更后发布 RolePermissionChangedEvent → **Outbox** → 清除该角色下所有用户的 permissionCache + userMenuCache（L1 + L2） |
| 所属 Phase | Phase 20 |

#### L2-D02-F03 角色-自定义数据范围部门

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_role_dept`（role_id, dept_id, tenant_id） |
| 功能 | 当 data_scope=CUSTOM 时，关联角色可访问的部门集合 |
| API | `PUT /api/v1/roles/{id}/data-scope` |
| 所属 Phase | Phase 21 |

### L2-D03 菜单管理

#### L2-D03-F01 菜单 CRUD 与树形查询

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_menu`（平台级，无 tenant_id） |
| 关键字段 | id, parent_id, menu_name, **names(JSONB)**（多语言，如 `{"zh":"用户管理","en":"User Management"}`）, menu_type(D 目录/M 菜单/B 按钮), path, component, permission, icon, sort_order, visible, status, descendant_ids(BIGINT[]), 审计列 |
| API | `GET /api/v1/menus/tree`（全量树）、`GET /api/v1/menus/current`（当前用户专属树）、`GET/POST/PUT/DELETE /api/v1/menus` |
| 权限 | `system:menu:list`, `system:menu:query`, `system:menu:add`, `system:menu:edit`, `system:menu:delete` |
| 前端联动 | 登录后动态拉取路由；`usePermissionStore` 存权限 Set（O(1) 检查）；`v-hasPermission` 指令控制按钮显隐 |
| 所属 Phase | Phase 20 |

### L2-D04 部门管理

#### L2-D04-F01 部门 CRUD 与树形管理

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_dept` |
| 关键字段 | id, tenant_id, parent_id, dept_name, **leader_user_id BIGINT REFERENCES sys_user(id)**（~~原 leader VARCHAR 已废弃~~）, phone, email, sort_order, status, descendant_ids(BIGINT[]), 审计列 |
| 辅助表 | `sys_dept_closure`（ancestor, descendant, depth, tenant_id）—— 闭包表加速权限查询 |
| **负责人关联表** | `sys_dept_leader`（dept_id, user_id, **leader_type(MAIN/DEPUTY)**）—— 支持正副负责人 |
| 维护机制 | 触发器函数 `refresh_dept_descendants` 自动更新 descendant_ids 数组；闭包表同步更新 |
| 索引 | sys_dept: `idx_dept_tenant_parent(tenant_id, parent_id) WHERE deleted = FALSE`；`GIN(descendant_ids)`；sys_dept_closure: `PK(ancestor,descendant)`、`idx_descendant(descendant,ancestor)`、`idx_tenant_ancestor(tenant_id,ancestor,descendant)` |
| API | `GET /api/v1/depts/tree`, `GET /api/v1/depts/{id}`, `POST/PUT/DELETE /api/v1/depts` |
| 权限 | `system:dept:list`, `system:dept:query`, `system:dept:add`, `system:dept:edit`, `system:dept:delete` |
| 所属 Phase | Phase 21 |

### L2-D05 岗位管理

#### L2-D05-F01 岗位 CRUD

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_post` |
| 关键字段 | id, tenant_id, post_code, post_name, sort_order, status, 审计列 |
| API | `GET/POST/PUT/DELETE /api/v1/posts`, `GET /api/v1/posts/{id}` |
| 权限 | `system:post:list`, `system:post:query`, `system:post:add`, `system:post:edit`, `system:post:delete` |
| 所属 Phase | Phase 20 |

### L2-D06 数据权限

#### L2-D06-F01 DataScopeInterceptor

| 项目 | 内容 |
|------|------|
| 功能 | MyBatis Executor 拦截器，根据用户角色的 data_scope 自动注入 dept_id 过滤条件 |
| 范围类型 | ALL（不过滤）、DEPT_AND_CHILD（本部门及子部门）、DEPT（仅本部门）、SELF（仅自己创建）、CUSTOM（自定义部门集合） |
| SQL 注入方式 | 预计算用户可访问部门 ID 集合（闭包表查询），JSqlParser 注入常量 `IN (...)` 子句（集合 <200），否则降级为子查询 |
| **"部门负责人 / 上级"解析** | 当前用户 → `sys_user.dept_id` → `sys_dept_leader`（MAIN 类型）→ 找不到则 `sys_dept.leader_user_id`；"上级审批"通过 `sys_dept_closure` 向上递归 |
| 缓存 | **dataScopeCache：Caffeine L1(2min) + Redis L2(5min)**（第二档） |
| 所属 Phase | Phase 21 |

### L2-D07 认证

#### L2-D07-F01 JWT 认证

| 项目 | 内容 |
|------|------|
| Token 内容 | **仅含** sub(userId), tid(tenantId), jti, iat, exp —— 不含权限信息 |
| 权限获取 | 请求时从 **permissionCache（Caffeine L1 + Redis L2）** 加载 |
| API | `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`, `POST /api/v1/auth/logout` |
| **登录返回** | 单次 payload：user info + permission Set + menu tree（减少后续请求） |
| 所属 Phase | Phase 5（基础）、Phase 22（增强：JWT 瘦身 + 缓存重写） |

#### L2-D07-F02 登录安全增强

| 项目 | 内容 |
|------|------|
| 功能 | 密码策略（L0-D04-F06）、验证码、登录失败锁定（5 次失败锁定 30 分钟，**Redis 计数器**） |
| 所属 Phase | Phase 22 |

#### L2-D07-F03 Token 黑名单

| 项目 | 内容 |
|------|------|
| 功能 | 强制下线时将 Token jti 加入黑名单 |
| 存储 | **Redis SET**（非 Caffeine）：`blacklist:{jti}`，TTL 与 Token 过期时间对齐 |
| 所属 Phase | Phase 22 |

### L2-D08 在线用户管理

#### L2-D08-F01 在线用户列表与强制踢出

| 项目 | 内容 |
|------|------|
| 存储 | **Redis HASH**：`online:{tokenId}` → {userId, username, ip, loginTime, browser, os, podName} |
| API | `GET /api/v1/online-users`, `DELETE /api/v1/online-users/{tokenId}` |
| 强制踢出 | 删除 Redis online key + 写入 tokenBlacklist + **WebSocket 推送 FORCE_LOGOUT** |
| 权限 | `system:online:list`, `system:online:forceLogout` |
| 所属 Phase | Phase 22 |

### L2-D09 个人中心

#### L2-D09-F01 个人信息管理

| 项目 | 内容 |
|------|------|
| 功能 | 查看 / 修改个人信息、修改密码、上传头像 |
| 缓存 | `userProfileCache`：Caffeine Only TTL 30min（第三档） |
| 安全 | 仅操作当前登录用户，服务层强制基于 SecurityContext.userId |
| API | `GET /api/v1/profile`, `PUT /api/v1/profile`, `PUT /api/v1/profile/password`, `POST /api/v1/profile/avatar` |
| 所属 Phase | Phase 22 |

---

## 五、L3 基础能力层

### L3-D01 字典管理

#### L3-D01-F01 字典类型 CRUD

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_dict_type` |
| API | `GET/POST/PUT/DELETE /api/v1/dicts` |
| 权限 | `system:dict:list`, `system:dict:query`, `system:dict:add`, `system:dict:edit`, `system:dict:delete` |
| 所属 Phase | Phase 7 |

#### L3-D01-F02 字典数据项 CRUD

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_dict_data` |
| 关键字段 | id, dict_type, dict_label, **labels(JSONB)**（多语言）, dict_value, sort_order, status |
| 索引 | `(dict_type, status)` |
| 缓存 | dictCache：Caffeine Only TTL 1h（第三档） |
| API | `GET/POST/PUT/DELETE /api/v1/dicts/{type}/items` |
| 所属 Phase | Phase 7 |

### L3-D02 系统参数配置

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_config` |
| 缓存 | configCache：Caffeine Only TTL 1h（第三档） |
| API | `GET/POST/PUT/DELETE /api/v1/configs`, `GET /api/v1/configs/key/{configKey}` |
| 权限 | `system:config:list`, `system:config:query`, `system:config:add`, `system:config:edit`, `system:config:delete` |
| 所属 Phase | Phase 7 |

### L3-D03 文件管理

#### L3-D03-F01 文件上传 / 下载 / 列表 / 删除

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_file` |
| 抽象层 | `FileStorageService`（upload, download, delete）→ 先实现 `LocalFileStorageService`，后续可换 MinIO/OSS |
| 路径隔离 | `/uploads/tenant/{tenantId}/` |
| API | `POST /api/v1/files/upload`, `GET /api/v1/files`, `GET /api/v1/files/{id}/download`, `DELETE /api/v1/files/{id}` |
| 权限 | `system:file:list`, `system:file:upload`, `system:file:download`, `system:file:delete` |
| 所属 Phase | Phase 9 |

### L3-D04 通知公告

#### L3-D04-F01 公告管理

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_notice` |
| API | `GET/POST/PUT/DELETE /api/v1/notices`, `GET /api/v1/notices/{id}` |
| 权限 | `system:notice:list`, `system:notice:query`, `system:notice:add`, `system:notice:edit`, `system:notice:delete` |
| 所属 Phase | Phase 10 |

#### L3-D04-F02 公告已读状态

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_notice_read` |
| API | `POST /api/v1/notices/{id}/read`, `GET /api/v1/notices/unread-count` |
| 所属 Phase | Phase 24 |

### L3-D05 任务调度

#### L3-D05-F01 Quartz 定时任务管理

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_job` + Quartz 标准表（11 张） |
| API | `GET/POST/PUT/DELETE /api/v1/jobs`, `PUT /api/v1/jobs/{id}/pause`, `PUT /api/v1/jobs/{id}/resume`, `POST /api/v1/jobs/{id}/run` |
| 权限 | `system:job:list`, `system:job:query`, `system:job:add`, `system:job:edit`, `system:job:delete`, `system:job:run`, `system:job:pause` |
| 所属 Phase | Phase 8 |

#### L3-D05-F02 任务执行日志

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_job_log`（按月分区） |
| API | `GET /api/v1/jobs/{id}/logs` |
| 保留策略 | 3 个月 |
| 所属 Phase | Phase 8 |

### L3-D06 数据导入导出

#### L3-D06-F01 导入导出中心

| 项目 | 内容 |
|------|------|
| 功能 | 统一框架（EasyExcel / Apache POI Streaming）：模板下载、逐行校验、异步导入（大文件走 Quartz 异步任务 + 进度通知）、导出文件缓存 |
| 核心表 | `sys_import_export_task` |
| 关键字段 | id, tenant_id, task_type(IMPORT/EXPORT), biz_type, status(PENDING/PROCESSING/SUCCESS/FAILED), file_id, error_file_id, total_count, success_count, error_count, operator_id, created_time |
| API | `POST /api/v1/import-export/import`, `POST /api/v1/import-export/export`, `GET /api/v1/import-export/tasks`, `GET /api/v1/import-export/tasks/{id}` |
| 权限 | 复用各业务模块的 export/import 权限 |
| 所属 Phase | Phase 30 |

### L3-D07 代码生成器

#### L3-D07-F01 代码生成

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_gen_table`, `sys_gen_table_column` |
| API | `GET /api/v1/gen/tables`, `POST /api/v1/gen/tables/import`, `GET/PUT /api/v1/gen/tables/{id}`, `POST /api/v1/gen/{tableId}/preview`, `POST /api/v1/gen/{tableId}/download` |
| 权限 | `system:gen:list`, `system:gen:query`, `system:gen:import`, `system:gen:edit`, `system:gen:preview`, `system:gen:download`, `system:gen:delete` |
| 所属 Phase | Phase 24 |

### L3-D08 系统监控

#### L3-D08-F01 服务器与缓存监控

| 项目 | 内容 |
|------|------|
| 功能 | JVM、CPU、内存、磁盘、**Redis 连接状态**、Caffeine 缓存统计 |
| API | `GET /api/v1/monitor/server`, `GET /api/v1/monitor/cache` |
| 权限 | `system:monitor:view` |
| 所属 Phase | Phase 24 |

### L3-D09 数据大屏

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_data_screen` |
| 所属 Phase | Phase 11 |

### L3-D10 前端应用

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_front_app` |
| 所属 Phase | Phase 12 |

---

## 六、L4 开放与集成层

### L4-D01 开放 API 管理

#### L4-D01-F01 开放应用管理

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_open_app` |
| 关键字段 | id, tenant_id, app_name, app_key, app_secret, **app_secret_secondary**（轮换副密钥）, **secret_expire_time**（旧密钥过期时间）, **auth_type(HMAC)**（预留 OAUTH2）, status, rate_limit_per_second, rate_limit_per_day, ip_whitelist(TEXT[]), 审计列 |
| API 白名单表 | `sys_open_app_api`（app_id, api_pattern, rate_limit_per_second） |
| 认证流程 | ① 校验 `\|server_time - X-Timestamp\| < 300s` → ② Redis SETNX `open:nonce:{appKey}:{nonce}` TTL 300s → ③ 验签 HMAC-SHA256(app_secret, method + uri + timestamp + nonce + body_hash) → ④ 验签失败时用 secondary 密钥重试 |
| **租户绑定** | tenant_id 从 `sys_open_app.tenant_id` 获取，**忽略请求头 X-Tenant-Id** |
| **限流** | 三级：全局 → 按 app_key（sys_open_app.rate_limit_*）→ 按 app_key + uri（sys_open_app_api.rate_limit_*）；**Redis + Lua 滑动窗口** |
| 密钥轮换流程 | 管理员生成新密钥 → 写入 secondary → 通知对接方 → 确认后提升 secondary → 清空旧密钥 |
| 审计 | 操作日志中 operator_type = `OPEN_API`、记录 app_key |
| API | `GET/POST/PUT/DELETE /api/v1/open-apps`, `GET /api/v1/open-apps/{id}`, `POST /api/v1/open-apps/{id}/regenerate-secret`, `GET /api/v1/open-apps/{id}/stats` |
| 权限 | `system:openapp:list`, `system:openapp:query`, `system:openapp:add`, `system:openapp:edit`, `system:openapp:delete` |
| 所属 Phase | **Phase 29** |

#### L4-D01-F02 数据同步接口

| 项目 | 内容 |
|------|------|
| 功能 | 批量同步 API：`POST /open/v1/sync/users`、`POST /open/v1/sync/depts` |
| 模式 | 全量 / 增量（基于 updated_time delta） |
| 审计 | 所有同步操作记入操作日志 + 数据变更审计 |
| **脱敏** | 响应数据经过 @DataMask 处理 |
| 所属 Phase | Phase 29 |

### L4-D02 Webhook 事件推送

#### L4-D02-F01 Webhook 配置与推送

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_webhook`（webhook_url, secret, event_types(TEXT[]), tenant_id, status） |
| 日志表 | `sys_webhook_log`（webhook_id, event_type, request_body, response_status, response_body, duration_ms, retry_count, status, created_time） |
| **投递方式** | 通过 **Outbox 表**保证一致性：业务事务写 sys_outbox_event → Outbox 消费者匹配 Webhook 配置 → HTTP POST |
| 推送体 | `{event_type, timestamp, tenant_id, trace_id, data}`，请求头含 `X-Webhook-Signature: HMAC-SHA256(secret, body)` |
| 重试策略 | 1min → 5min → 30min → FAILED 并告警 |
| API | `GET/POST/PUT/DELETE /api/v1/webhooks`, `GET /api/v1/webhooks/{id}/logs` |
| 权限 | `system:webhook:list`, `system:webhook:query`, `system:webhook:add`, `system:webhook:edit`, `system:webhook:delete` |
| 所属 Phase | Phase 29 |

### L4-D03 消息中台

#### L4-D03-F01 消息模板引擎

| 项目 | 内容 |
|------|------|
| 核心表 | `msg_template` |
| 关键字段 | id, template_code, template_name, channel_type(SMS/EMAIL/WECHAT_WORK/DINGTALK/WEBSOCKET/APP_PUSH), content_template(Thymeleaf), tenant_id, status |
| 统一接口 | `MessageSendService.send(templateCode, variables, receivers)` → 按 channel_type 分派到 ChannelAdapter |
| 已实现适配器 | `EmailChannelAdapter`（Spring Boot Mail，自动使用租户品牌 email 分类签名）、`WebSocketChannelAdapter`（复用已有 WebSocket） |
| SPI 扩展 | 其他渠道通过 SPI 扩展；配置存 sys_config |
| API | `GET/POST/PUT/DELETE /api/v1/msg-templates` |
| 权限 | `system:msgtemplate:list`, `system:msgtemplate:query`, `system:msgtemplate:add`, `system:msgtemplate:edit`, `system:msgtemplate:delete` |
| 所属 Phase | Phase 28 |

#### L4-D03-F02 消息发送日志

| 项目 | 内容 |
|------|------|
| 核心表 | `msg_send_log` |
| 关键字段 | id, template_code, channel_type, receiver, content, send_status(SUCCESS/FAILED), retry_count, error_msg, tenant_id, created_time |
| 功能 | 所有消息发送记录日志，失败可手动 / 自动重发 |
| API | `GET /api/v1/msg-logs` |
| 权限 | `system:msglog:list` |
| 所属 Phase | Phase 28 |

---

## 七、L5 业务扩展层

### L5-D01 流程引擎

#### L5-D01-F01 流程定义管理

| 项目 | 内容 |
|------|------|
| 核心表 | `wf_process_def` |
| 关键字段 | id, tenant_id, process_name, process_key, **form_def_id**(关联自定义表单), definition(JSONB，存储节点配置), version, status, 审计列 |
| 支持节点 | 发起人、审批人（指定人 / 指定角色 / **部门负责人** / 上级）、会签、或签、条件分支、抄送、结束 |
| 审批动作 | 同意、驳回（回到上一步 / 回到发起人）、转办、加签 |
| 前端设计器 | 可视化拖拽（AntV X6 / LogicFlow），生成 JSON 存入 definition |
| API | `GET/POST/PUT/DELETE /api/v1/wf/process-defs`, `GET /api/v1/wf/process-defs/{id}` |
| 权限 | `workflow:def:list`, `workflow:def:query`, `workflow:def:add`, `workflow:def:edit`, `workflow:def:delete` |
| 所属 Phase | Phase 32 |

#### L5-D01-F02 流程实例管理

| 项目 | 内容 |
|------|------|
| 核心表 | `wf_process_instance` |
| 关键字段 | id, tenant_id, process_def_id, **initiator_id**, initiator_dept_id, form_data_id, status(RUNNING/COMPLETED/REJECTED/CANCELLED), current_node, created_time, completed_time |
| **可见性模型（6 级）** | ① 发起人始终可见 → ② 当前待办人可见 → ③ 历史办理人可见 → ④ 抄送人可见（只读）→ ⑤ 流程管理员（`workflow:instance:manage`）可见本租户全部 → ⑥ 部门范围管理员（`workflow:instance:dept`）结合 DataScopeInterceptor 可见本部门及下属部门 |
| 索引 | `(tenant_id, initiator_id, status)`、`(tenant_id, initiator_dept_id, status)` |
| API | `POST /api/v1/wf/instances`（发起）、`GET /api/v1/wf/instances`（列表）、`GET /api/v1/wf/instances/{id}`、`PUT /api/v1/wf/instances/{id}/cancel` |
| 权限 | `workflow:instance:list`, `workflow:instance:query`, `workflow:instance:start`, `workflow:instance:cancel`, `workflow:instance:manage`, `workflow:instance:dept` |
| 所属 Phase | Phase 32 |

#### L5-D01-F03 待办 / 已办任务

| 项目 | 内容 |
|------|------|
| 核心表 | `wf_task`（待办）、`wf_task_history`（已办） |
| 关键字段 | wf_task: id, tenant_id, instance_id, node_name, **assignee_id**, task_type(APPROVE/COUNTERSIGN/CC), status(PENDING/COMPLETED/REJECTED/TRANSFERRED), created_time；wf_task_history 增加 action, comment, duration_ms, completed_time |
| 索引 | wf_task: `(tenant_id, assignee_id, status)`；wf_task_history: `(tenant_id, assignee_id, completed_time DESC)` |
| **审批人解析** | "部门负责人"：`sys_dept_leader`（MAIN 类型）→ 降级 `sys_dept.leader_user_id`；"上级"：当前用户 dept → `sys_dept_closure` 向上查 parent → parent 的 leader_user_id |
| **一致性保证** | 节点推进在同一事务中写 wf_task + wf_task_history + **sys_outbox_event**（待办通知、Webhook、审计） |
| API | `GET /api/v1/wf/tasks/todo`（我的待办）、`GET /api/v1/wf/tasks/done`（我的已办）、`POST /api/v1/wf/tasks/{id}/approve`、`POST /api/v1/wf/tasks/{id}/reject`、`POST /api/v1/wf/tasks/{id}/transfer` |
| 权限 | `workflow:task:list`, `workflow:task:approve`, `workflow:task:reject`, `workflow:task:transfer` |
| 所属 Phase | Phase 32 |

### L5-D02 自定义表单

#### L5-D02-F01 表单定义管理

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_form_def` |
| 关键字段 | id, tenant_id, form_name, form_key, **schema(JSONB)**（字段列表、校验规则、布局）, version, status, 审计列 |
| 支持字段类型 | 单行文本、多行文本、数字、日期 / 日期范围、单选 / 多选、下拉（关联字典）、文件上传、用户选择器、部门选择器、关联数据、子表格、分组面板 |
| 前端设计器 | 基于 FcDesigner / Formily 拖拽设计 |
| API | `GET/POST/PUT/DELETE /api/v1/form-defs`, `GET /api/v1/form-defs/{id}` |
| 权限 | `form:def:list`, `form:def:query`, `form:def:add`, `form:def:edit`, `form:def:delete` |
| 所属 Phase | Phase 31 |

#### L5-D02-F02 表单数据存储与查询

| 项目 | 内容 |
|------|------|
| 核心表 | `sys_form_data` |
| 关键字段 | id, tenant_id, form_def_id, **field_values(JSONB)**, creator_id, created_time, updated_time |
| **检索策略（分阶段）** | **MVP**：列表仅支持固定元字段筛选（form_def_id、creator_id、created_time 范围、关联流程 status）→ **增强**：高频字段通过 **PostgreSQL Generated Column + 表达式索引**（在表单设计器中标记"可检索"，系统自动执行 DDL）→ **兜底**：`GIN(field_values jsonb_path_ops)` 支持 `@>` 等值匹配 |
| API | `POST /api/v1/form-data`, `GET /api/v1/form-data`, `GET /api/v1/form-data/{id}`, `PUT /api/v1/form-data/{id}` |
| 权限 | `form:data:list`, `form:data:query`, `form:data:add`, `form:data:edit` |
| 所属 Phase | Phase 31 |

#### L5-D02-F03 自定义字段扩展（EAV-JSONB）

| 项目 | 内容 |
|------|------|
| 功能 | 对 sys_user 等核心表支持租户级自定义字段 |
| 定义表 | `sys_custom_field_def`（tenant_id, entity_type, field_key, field_label, field_type, required, sort_order） |
| 存储 | 核心表的 `ext_fields JSONB` 列 |
| 索引 | 按需对热门自定义字段建 GIN 或 Generated Column 索引 |
| API | `GET/POST/PUT/DELETE /api/v1/custom-fields` |
| 权限 | `system:customfield:list`, `system:customfield:add`, `system:customfield:edit`, `system:customfield:delete` |
| 所属 Phase | Phase 31 |

### L5-D03 报表引擎

#### L5-D03-F01 报表定义与查询

| 项目 | 内容 |
|------|------|
| 核心表 | `rpt_report_def` |
| 关键字段 | id, tenant_id, report_name, data_source_type(SQL/API), query_template, column_def(JSONB), filter_def(JSONB) |
| 安全 | SQL 模板使用 `#{}` 参数化占位符，后端安全替换 |
| API | `GET/POST/PUT/DELETE /api/v1/reports`, `POST /api/v1/reports/{id}/execute` |
| 权限 | `report:def:list`, `report:def:query`, `report:def:add`, `report:def:edit`, `report:def:delete`, `report:def:execute` |
| 所属 Phase | Phase 30（与导入导出同期） |

### L5-D04 AI 智能助手

#### L5-D04-F01 智能运维 Agent

| 项目 | 内容 |
|------|------|
| 功能 | 基于 Spring AI + MCP 构建 AI Agent，暴露平台日志 / 指标 / 告警 / 在线用户 / 定时任务 / 慢 SQL 查询为 MCP Tool |
| 模型切换 | Spring AI ChatModel 抽象层，sys_config 配置模型提供商（OpenAI / 通义千问 / DeepSeek）和 API Key |
| 前端入口 | "系统监控"页面增加 AI 对话窗口 |
| **安全** | Agent 拥有独立的 RBAC 权限上下文，仅可调用只读 Tool；Agent 对话记录写入审计日志 |
| 配置表 | `sys_ai_config`（provider, model, api_key_encrypted, temperature, max_tokens） |
| 日志表 | `sys_ai_conversation_log`（tenant_id, user_id, question, answer, tool_calls(JSONB), tokens_used, duration_ms, created_time） |
| API | `POST /api/v1/ai/chat`, `GET /api/v1/ai/conversations` |
| 权限 | `system:ai:chat`, `system:ai:config`, `system:ai:log:list` |
| 所属 Phase | Phase 33 |

---

## 八、完整权限字符串清单（132 个）

```
# ═══ L1 平台治理层 ═══

# 租户管理 (5)
system:tenant:list
system:tenant:query
system:tenant:add
system:tenant:edit
system:tenant:delete

# 租户套餐 (5)
system:package:list
system:package:query
system:package:add
system:package:edit
system:package:delete

# 品牌配置-超管 (2)
system:brand:list
system:brand:edit

# 品牌配置-租户 (2)
tenant:brand:list
tenant:brand:edit

# 计量计费 (1)
system:billing:list

# 帮助中心 (4)
system:help:list
system:help:add
system:help:edit
system:help:delete

# ═══ L2 身份与权限层 ═══

# 用户管理 (8)
system:user:list
system:user:query
system:user:add
system:user:edit
system:user:delete
system:user:resetPwd
system:user:export
system:user:import

# 角色管理 (5)
system:role:list
system:role:query
system:role:add
system:role:edit
system:role:delete

# 菜单管理 (5)
system:menu:list
system:menu:query
system:menu:add
system:menu:edit
system:menu:delete

# 部门管理 (5)
system:dept:list
system:dept:query
system:dept:add
system:dept:edit
system:dept:delete

# 岗位管理 (5)
system:post:list
system:post:query
system:post:add
system:post:edit
system:post:delete

# 在线用户 (2)
system:online:list
system:online:forceLogout

# ═══ L3 基础能力层 ═══

# 字典管理 (5)
system:dict:list
system:dict:query
system:dict:add
system:dict:edit
system:dict:delete

# 参数配置 (5)
system:config:list
system:config:query
system:config:add
system:config:edit
system:config:delete

# 文件管理 (4)
system:file:list
system:file:upload
system:file:download
system:file:delete

# 通知公告 (5)
system:notice:list
system:notice:query
system:notice:add
system:notice:edit
system:notice:delete

# 定时任务 (7)
system:job:list
system:job:query
system:job:add
system:job:edit
system:job:delete
system:job:run
system:job:pause

# 代码生成 (7)
system:gen:list
system:gen:query
system:gen:import
system:gen:edit
system:gen:preview
system:gen:download
system:gen:delete

# 系统监控 (1)
system:monitor:view

# ═══ L0 横切 - 审计 ═══

# 操作日志 (4)
system:operlog:list
system:operlog:query
system:operlog:delete
system:operlog:export

# 登录日志 (4)
system:loginlog:list
system:loginlog:query
system:loginlog:delete
system:loginlog:export

# 数据变更审计 (1)
system:changelog:list

# ═══ L0 横切 - 安全 ═══

# 数据脱敏 (1)
system:data:unmask

# ═══ L4 开放与集成层 ═══

# 开放应用 (5)
system:openapp:list
system:openapp:query
system:openapp:add
system:openapp:edit
system:openapp:delete

# Webhook (5)
system:webhook:list
system:webhook:query
system:webhook:add
system:webhook:edit
system:webhook:delete

# 消息模板 (5)
system:msgtemplate:list
system:msgtemplate:query
system:msgtemplate:add
system:msgtemplate:edit
system:msgtemplate:delete

# 消息日志 (1)
system:msglog:list

# ═══ L5 业务扩展层 ═══

# 流程定义 (5)
workflow:def:list
workflow:def:query
workflow:def:add
workflow:def:edit
workflow:def:delete

# 流程实例 (6)
workflow:instance:list
workflow:instance:query
workflow:instance:start
workflow:instance:cancel
workflow:instance:manage
workflow:instance:dept

# 流程任务 (4)
workflow:task:list
workflow:task:approve
workflow:task:reject
workflow:task:transfer

# 表单定义 (5)
form:def:list
form:def:query
form:def:add
form:def:edit
form:def:delete

# 表单数据 (4)
form:data:list
form:data:query
form:data:add
form:data:edit

# 自定义字段 (4)
system:customfield:list
system:customfield:add
system:customfield:edit
system:customfield:delete

# 报表 (6)
report:def:list
report:def:query
report:def:add
report:def:edit
report:def:delete
report:def:execute

# AI 助手 (3)
system:ai:chat
system:ai:config
system:ai:log:list

# ═══ 合计：132 个 ═══
```

---

## 九、完整数据库表清单（58 张）

### L1 平台治理层（6 张）

| 序号 | 表名 | 说明 | 分区 |
|------|------|------|------|
| 1 | sys_tenant | 租户 | — |
| 2 | sys_tenant_package | 租户套餐 | — |
| 3 | sys_tenant_brand | 租户品牌配置 | — |
| 4 | bill_usage_record | 用量统计 | — |
| 5 | sys_help_doc | 帮助文档 | — |
| 6 | sys_outbox_event | **Outbox 事件表** | — (定期清理) |

### L2 身份与权限层（11 张）

| 序号 | 表名 | 说明 |
|------|------|------|
| 7 | sys_user | 用户 |
| 8 | sys_role | 角色 |
| 9 | sys_menu | 菜单 |
| 10 | sys_dept | 部门 |
| 11 | sys_dept_closure | 部门闭包表 |
| 12 | **sys_dept_leader** | **部门负责人关联（正/副）** |
| 13 | sys_post | 岗位 |
| 14 | sys_user_role | 用户-角色 |
| 15 | sys_user_post | 用户-岗位 |
| 16 | sys_role_menu | 角色-菜单 |
| 17 | sys_role_dept | 角色-自定义数据范围部门 |

### L3 基础能力层（11 张）

| 序号 | 表名 | 说明 | 分区 |
|------|------|------|------|
| 18 | sys_dict_type | 字典类型 | — |
| 19 | sys_dict_data | 字典数据 | — |
| 20 | sys_config | 系统参数 | — |
| 21 | sys_notice | 通知公告 | — |
| 22 | sys_notice_read | 公告已读 | — |
| 23 | sys_file | 文件记录 | — |
| 24 | sys_job | 定时任务 | — |
| 25 | sys_job_log | 任务日志 | 按月 |
| 26 | sys_import_export_task | 导入导出任务 | — |
| 27 | sys_gen_table | 代码生成-表 | — |
| 28 | sys_gen_table_column | 代码生成-列 | — |

### L0 横切 - 审计（3 张，均分区）

| 序号 | 表名 | 分区策略 | 保留期 |
|------|------|----------|--------|
| 29 | sys_operation_log | 按月 RANGE | 6 个月 |
| 30 | sys_login_log | 按月 RANGE | 6 个月 |
| 31 | sys_data_change_log | 按月 RANGE | 12 个月 |

### L4 开放与集成层（5 张）

| 序号 | 表名 | 说明 |
|------|------|------|
| 32 | sys_open_app | 开放应用 |
| 33 | sys_open_app_api | 应用 API 白名单 |
| 34 | sys_webhook | Webhook 配置 |
| 35 | sys_webhook_log | Webhook 推送日志 |
| 36 | msg_template | 消息模板 |
| 37 | msg_send_log | 消息发送日志 |

### L5 业务扩展层（9 张）

| 序号 | 表名 | 说明 |
|------|------|------|
| 38 | wf_process_def | 流程定义 |
| 39 | wf_process_instance | 流程实例 |
| 40 | wf_task | 待办任务 |
| 41 | wf_task_history | 历史任务 |
| 42 | sys_form_def | 表单定义 |
| 43 | sys_form_data | 表单数据 |
| 44 | sys_custom_field_def | 自定义字段定义 |
| 45 | rpt_report_def | 报表定义 |
| 46 | sys_ai_config | AI 配置 |
| 47 | sys_ai_conversation_log | AI 对话日志 |

### 其他（11 张）

| 序号 | 表名 | 说明 |
|------|------|------|
| 48 | sys_data_screen | 数据大屏 |
| 49 | sys_front_app | 前端应用 |
| 50-58 | qrtz_* (9 张) | Quartz 标准表 |

**合计：58 张**

---

## 十、Flyway 迁移脚本序列（V001-V045）

| 版本 | 内容 | 所属层 |
|------|------|--------|
| V001 | sys_tenant | L1 |
| V002 | sys_user（含 dept_id、ext_fields JSONB） | L2 |
| V003 | sys_role（含 data_scope） | L2 |
| V004 | sys_user_role | L2 |
| V005 | sys_menu（含 names JSONB、descendant_ids） | L2 |
| V006 | sys_role_menu | L2 |
| V007 | sys_dept（**leader_user_id BIGINT**）+ sys_dept_closure + **sys_dept_leader** | L2 |
| V008 | sys_role_dept | L2 |
| V009 | sys_post + sys_user_post | L2 |
| V010 | sys_dict_type + sys_dict_data（含 labels JSONB） | L3 |
| V011 | sys_config | L3 |
| V012 | sys_notice + sys_notice_read | L3 |
| V013 | sys_file | L3 |
| V014 | sys_job + sys_job_log（分区）+ Quartz 标准表 | L3 |
| V015 | sys_operation_log（分区） | L0 |
| V016 | sys_login_log（分区） | L0 |
| V017 | sys_data_change_log（分区） | L0 |
| V018 | sys_tenant_brand + 初始化数据 | L1 |
| V019 | sys_tenant 增加 domain/subdomain 字段 | L1 |
| V020 | sys_tenant_package | L1 |
| V021 | sys_data_screen | L3 |
| V022 | sys_front_app | L3 |
| V023 | sys_gen_table + sys_gen_table_column | L3 |
| V024 | **sys_outbox_event** | L0 |
| V025 | 菜单初始化数据（完整菜单树 + 按钮权限） | L2 |
| V026 | 字典初始化数据 | L3 |
| V027 | 默认超级管理员 + 默认角色 + 默认租户 | L1+L2 |
| V028 | 索引补充（partial index、GIN index、BRIN index） | 全局 |
| V029 | 分区表自动创建未来 3 个月分区的存储过程 | L0 |
| V030 | 部门 descendant_ids 触发器函数 | L2 |
| V031 | msg_template + msg_send_log | L4 |
| V032 | sys_open_app（含 **secondary secret、auth_type**）+ sys_open_app_api | L4 |
| V033 | sys_webhook + sys_webhook_log | L4 |
| V034 | sys_import_export_task | L3 |
| V035 | rpt_report_def | L5 |
| V036 | sys_form_def + sys_form_data（含 GIN 索引） | L5 |
| V037 | sys_custom_field_def | L5 |
| V038 | wf_process_def + wf_process_instance + wf_task + wf_task_history | L5 |
| V039 | sys_ai_config + sys_ai_conversation_log | L5 |
| V040 | bill_usage_record | L1 |
| V041 | sys_help_doc | L1 |
| V042 | 扩展功能菜单初始化数据（消息、开放平台、工作流、表单、报表、AI） | 全局 |
| V043 | 扩展功能权限字符串初始化 | 全局 |
| V044 | 品牌配置增加 mobile category 初始化数据 | L1 |
| V045 | 索引补充（工作流/表单/消息/开放平台相关索引） | 全局 |

---

## 十一、Phase 路线图（修订版）

### 第一阶段：基座核心（Phase 1-12）

| Phase | 内容 | 关键修订点 |
|-------|------|-----------|
| 1-4 | 工程骨架、Spring Boot 配置、Web 过滤器（XSS）、统一响应、全局异常、**事件基类定义**、**全局异常含 DuplicateKeyException→409** | 新增事件基类 |
| **5** | JWT 认证、TenantContext、LogContextFilter、**Redis 连接配置 + RedisTemplate Bean** | **新增 Redis 基础依赖** |
| 6 | 用户、角色、租户基础 CRUD、用户-角色关联 | — |
| 7 | 字典（含数据项 + labels JSONB）、参数配置 | — |
| 8 | Quartz 定时任务 + 执行日志 | — |
| 9 | 文件上传/下载/列表（FileStorageService 抽象）、操作日志 | — |
| 10-12 | 公告、数据大屏、前端应用 | — |

### 第二阶段：权限与可观测（Phase 20-22）

| Phase | 内容 | 关键修订点 |
|-------|------|-----------|
| **20** | 菜单管理、岗位管理、角色-菜单关联、XSS 强化、统一错误码、结构化日志(JSON+MDC)、链路追踪(OpenTelemetry)、**Prometheus 低基数指标**、优雅停机、健康检查（**含 Redis readiness**）、**MultiLevelCacheManager(Caffeine L1 + Redis L2 + Pub/Sub)**、**Outbox 基础框架** | **缓存架构重写、Outbox 引入、Prometheus 无 tenantId label** |
| **21** | 部门管理（**leader_user_id + sys_dept_leader**）、闭包表、DataScopeInterceptor、租户初始化器、超级管理员、TenantAwareTaskDecorator、品牌配置、域名识别 | **dept 模型修订** |
| **22** | 个人中心、登录安全(密码策略/验证码/锁定)、登录日志、在线用户(**Redis HASH**)、Token 黑名单(**Redis SET**)、JWT 瘦身 + 权限缓存(**Caffeine L1 + Redis L2**) | **安全缓存全部走 Redis** |

### 第三阶段：前端 + 数据工具（Phase 23-24）

| Phase | 内容 |
|-------|------|
| 23 | 菜单/部门/岗位/角色/品牌管理 UI、租户套餐管理、动态路由、v-hasPermission、Pinia stores (user/app/permission/dict/tenant/brand) |
| 24 | 数据变更审计、公告已读、WebSocket 通知、系统监控页面、代码生成器 |

### 第四阶段：集成测试 + 生产就绪（Phase 25-27）

| Phase | 内容 | 关键修订点 |
|-------|------|-----------|
| 25 | 全模块集成测试、跨租户隔离(@WithTenant)、权限绕过测试、SQL 注入审计、EXPLAIN ANALYZE 验证 | — |
| 26 | K8s 部署编排、Fluent Bit+Loki、Prometheus+Grafana(**租户视图数据源=PostgreSQL**)、Tempo+OTel Collector、**Loki Alerting Rules(暴力登录检测)**、**Redis Sentinel 部署**、告警规则、HikariCP 调优、分区表维护 Job | **Redis 部署、Loki 告警替代 Prometheus 租户告警** |
| 27 | 性能压测、安全扫描、文档完善、交付演练 | — |

### 第五阶段：扩展功能（Phase 28-35）

| Phase | 内容 | 工期 | DoD 重点 |
|-------|------|------|----------|
| **28** | 消息中台（模板 + Email + WebSocket 渠道 + 日志）+ **Outbox 消费框架正式启用** | 2 周 | D4: 消息发送全链路审计；D5: 消息成功率指标 |
| **29** | **数据脱敏**（@DataMask）+ 开放平台（**HMAC + nonce/Redis + 时钟校验 + 密钥轮换** + Webhook/**Outbox** 投递） | 3 周 | D6: 脱敏绕过测试、nonce 重放测试、密钥轮换测试 |
| **30** | 数据导入导出中心 + 报表引擎 | 2 周 | D6: 10 万行异步导入压测 |
| **31** | 自定义表单设计器 + 动态字段（**JSONB、MVP 仅元字段筛选**） | 3 周 | D7: EXPLAIN ANALYZE 验证 JSONB 查询 |
| **32** | 轻量审批引擎（**6 级可见性 + dept leader_user_id + Outbox 一致性**） | 3 周 | D6: 跨租户流程隔离、可见性边界测试 |
| **33** | AI 运维助手（Spring AI + MCP，只读 Tool，RBAC 约束） | 2 周 | D4: AI 对话全量审计 |
| **34** | 移动端 H5 + 国际化（i18n） | 3 周 | D2: 移动端 5 大场景 UI 验收 |
| **35** | 运营仪表盘 + 计量计费 + 租户自助 + 帮助中心 | 3 周 | D5: 租户视图 Grafana 面板验收 |

---

## 十二、交付验收标准（DoD）

每个 Phase 必须满足以下 8 项才能标记 Done：

**D1 - API 完备性**：Swagger/OpenAPI 文档完整，请求 / 响应示例齐全，错误码覆盖所有异常路径，幂等接口标注规则。

**D2 - UI 完备性**：列表页（含空态、加载态、错误态）、详情页、新增 / 编辑表单、删除确认；v-hasPermission 正确隐藏无权按钮；响应式断点适配。

**D3 - 权限闭环**：最小权限集录入 sys_menu；超管 / 租户管理员 / 普通用户三种角色边界清晰；无权限返回 403 非 500；前端 v-hasPermission + 后端 @PreAuthorize 双重校验。

**D4 - 审计闭环**：写操作进入 sys_operation_log；敏感变更进入 sys_data_change_log；日志含 traceId、tenantId、userId。

**D5 - 可观测闭环**：关键链路可通过 traceId 端到端追踪；关键指标有 Grafana 面板；至少一条告警规则（PrometheusRule 或 Loki Alert）。

**D6 - 测试闭环**：跨租户隔离测试（@WithTenant）；权限绕过测试；并发 / 重复提交测试；核心查询 EXPLAIN ANALYZE 验证走索引且耗时达标。

**D7 - 数据库闭环**：Flyway 迁移幂等可重复执行；有回滚策略；分区 / 索引 / 约束完整；压测数据验证性能基准。

**D8 - 运维闭环**：K8s 资源清单更新；健康探针覆盖新增依赖；Fluent Bit 解析规则覆盖新增日志格式；蓝绿 / 滚动发布验证过回滚。

---

## 十三、K8s 基础设施清单（修订版）

| 组件 | 用途 | 资源 |
|------|------|------|
| PostgreSQL (StatefulSet / 外部 RDS) | 主数据库 | 2C4G |
| **Redis Sentinel (1 主 2 从 + 3 Sentinel)** | **缓存 L2 + 黑名单 + nonce + Pub/Sub + 限流** | **1.5C3G** |
| 应用 Pod (Deployment, **3 replicas**) | 业务服务 | 2C4G × 3 |
| Nginx Ingress Controller | 流量入口 + 通配符域名 | 0.5C1G |
| Fluent Bit (DaemonSet) | 日志采集 | 0.2C256M/node |
| Loki (StatefulSet) | 日志存储 + **租户维度 Alerting Rules** | 2C4G |
| Prometheus + Alertmanager | **低基数**指标 + 系统告警 | 2C4G |
| Grafana | 可视化（**租户视图数据源 = PostgreSQL**） | 1C2G |
| Tempo | 链路追踪 | 1C2G |
| OpenTelemetry Collector | Trace 中转 | 0.5C1G |
| kubernetes-event-exporter | K8s 事件 | 0.1C128M |
| **合计** | | **约 12C24G + 100Gi 存储** |

---

## 十四、前端状态管理清单（Pinia Stores）

| Store | 职责 | 数据来源 | 持久化 |
|-------|------|----------|--------|
| useUserStore | 当前用户信息 | `/api/v1/auth/login` payload | SessionStorage |
| usePermissionStore | 权限字符串 Set（O(1)） + 动态路由 | 登录 payload | SessionStorage |
| useDictStore | 全量字典缓存 | `/api/v1/dicts` 一次性拉取 | SessionStorage |
| useAppStore | 应用全局状态（侧边栏、设备） | 本地 | LocalStorage |
| useTenantStore | 当前租户信息 | 登录 payload / TenantResolver | SessionStorage |
| useBrandStore | 品牌配置（Logo、颜色、标题） | `/api/v1/brand/config`（登录前） | SessionStorage |

---

## 十五、平台全景数字

| 维度 | 数量 |
|------|------|
| 架构层次 | 5 层 + L0 横切 |
| 功能域 | 22 个 |
| 功能模块 | 68 个 |
| 数据库表 | 58 张 |
| 权限字符串 | 132 个 |
| API 端点 | ~320 个 |
| 缓存实例 | 15 个（3 类 Redis Only + 5 类 Caffeine+Redis + 4 类 Caffeine Only + 3 类 Redis 功能性） |
| Flyway 迁移 | V001-V045 |
| Phase | 1-35 |
| 预计总工期 | 基座 Phase 1-27 约 5 个月 + 扩展 Phase 28-35 约 5 个月 = **10 个月** |
| K8s 资源 | 12C24G + 100Gi |
