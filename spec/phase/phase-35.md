---
phase: 35
title: "结构化日志与 Loki 集成 (Structured Logging)"
targets:
  backend: true
  frontend: false
depends_on: [34]
bundle_with: []
scope:
  - "ljwx-platform-app/src/main/resources/logback-spring.xml"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/logging/LoggingFilter.java"
  - "ljwx-platform-core/src/main/java/com/ljwx/platform/core/logging/MDCKeys.java"
  - "ljwx-platform-app/src/main/resources/application.yml"
  - "k8s/fluent-bit-config.yaml"
---
# Phase 35 — 结构化日志与 Loki 集成

| 项目 | 值 |
|-----|---|
| Phase | 35 |
| 模块 | ljwx-platform-core (后端) + K8s 配置 |
| Feature | L0-D02-F01 |
| 前置依赖 | Phase 34 (Outbox 事件表) |
| 优先级 | 🔴 **P0 - 生产就绪必需** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/07-devops.md` — §日志采集
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 当前日志为纯文本格式,无法高效查询租户维度日志,排查问题困难。

**解决方案**:
1. Logback JSON 格式输出
2. MDC 注入 traceId、tenantId、userId
3. Fluent Bit 采集日志到 Loki
4. Grafana 查询和告警

---

## 日志格式契约

### JSON 日志字段

| 字段 | 类型 | 说明 |
|------|------|------|
| timestamp | string | ISO 8601 时间戳 |
| level | string | DEBUG / INFO / WARN / ERROR |
| logger | string | 日志记录器名称 |
| thread | string | 线程名 |
| message | string | 日志消息 |
| traceId | string | 链路追踪 ID |
| tenantId | long | 租户 ID |
| userId | long | 用户 ID |
| requestUri | string | 请求 URI |
| requestMethod | string | 请求方法 |
| clientIp | string | 客户端 IP |
| exception | object | 异常堆栈（如有） |

---

## MDC 注入

### LoggingFilter

```java
@Component
@Order(2)  // 在 TenantContextFilter (Order=1) 之后执行
public class LoggingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                   HttpServletResponse response,
                                   FilterChain filterChain) {
        try {
            // 注入 MDC (此时 TenantContext 已设置)
            MDC.put(MDCKeys.TRACE_ID, generateTraceId());
            MDC.put(MDCKeys.TENANT_ID, String.valueOf(TenantContext.getTenantId()));
            MDC.put(MDCKeys.USER_ID, String.valueOf(getUserId()));
            MDC.put(MDCKeys.REQUEST_URI, request.getRequestURI());
            MDC.put(MDCKeys.REQUEST_METHOD, request.getMethod());
            MDC.put(MDCKeys.CLIENT_IP, getClientIp(request));

            filterChain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
```

---

## Fluent Bit 配置

### fluent-bit-config.yaml

```yaml
[INPUT]
    Name              tail
    Path              /var/log/containers/*ljwx-platform*.log
    Parser            docker
    Tag               kube.*
    Refresh_Interval  5
    Mem_Buf_Limit     5MB

[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
    Merge_Log           On
    K8S-Logging.Parser  On
    K8S-Logging.Exclude On

[OUTPUT]
    Name   loki
    Match  kube.*
    Host   loki.monitoring.svc.cluster.local
    Port   3100
    Labels job=ljwx-platform, app=ljwx-platform, env=${ENV}
    RemoveKeys kubernetes,stream
```

---

## 业务规则

- **BL-35-01**：每个请求 → 生成唯一 traceId → 注入 MDC
- **BL-35-02**：TenantContext 存在 → 注入 tenantId → 方便租户维度查询
- **BL-35-03**：UserContext 存在 → 注入 userId → 方便用户维度查询
- **BL-35-04**：请求结束 → MDC.clear() → 避免线程池污染
- **BL-35-05**：异常日志 → 包含完整堆栈 → 方便排查问题

---

## 验收条件

- **AC-01**：日志输出为 JSON 格式
- **AC-02**：MDC 包含 traceId、tenantId、userId
- **AC-03**：Fluent Bit 正常采集日志到 Loki
- **AC-04**：Grafana 可按 tenantId 查询日志
- **AC-05**：异常日志包含完整堆栈

---

## 关键约束

- 日志格式：必须为 JSON,禁止纯文本
- MDC 清理：请求结束必须调用 MDC.clear()
- 敏感信息：禁止记录密码、Token 等敏感信息
