---
phase: 36
title: "Prometheus 指标监控 (Metrics Monitoring)"
targets:
  backend: true
  frontend: false
depends_on: [35]
bundle_with: []
scope:
  - "ljwx-platform-app/pom.xml"
  - "ljwx-platform-app/src/main/resources/application.yml"
  - "ljwx-platform-app/src/main/java/com/ljwx/platform/app/filter/TenantMetricsFilter.java"
  - "k8s/prometheus-servicemonitor.yaml"
---
# Phase 36 — Prometheus 指标监控

| 项目 | 值 |
|-----|---|
| Phase | 36 |
| 模块 | ljwx-platform-app (后端) + K8s 配置 |
| Feature | L0-D02-F02 |
| 前置依赖 | Phase 35 (结构化日志) |
| 测试契约 | `spec/tests/phase-36-metrics.tests.yml` |
| 优先级 | 🔴 **P0 - 生产就绪必需** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/07-devops.md` — §监控指标
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 无法监控系统健康和租户异常。

**解决方案**:
1. Micrometer + Prometheus 指标采集
2. 三层指标策略（低基数 + 租户维度 + 精确统计）
3. ServiceMonitor 自动发现
4. 告警规则

---

## 指标分层策略

| 层级 | 存储 | 基数 | 用途 | 示例 |
|------|------|------|------|------|
| **L1 低基数** | Prometheus | < 1000 | 全局监控 | JVM、HTTP 状态码 |
| **L2 租户维度** | Loki | 中等 | 租户异常 | 租户请求量、错误率 |
| **L3 精确统计** | PostgreSQL | 高 | 计费统计 | 租户 API 调用明细 |

---

## 核心指标

### JVM 指标

- `jvm_memory_used_bytes{area="heap"}`
- `jvm_gc_pause_seconds_sum`
- `jvm_threads_live`

### HTTP 指标

- `http_server_requests_seconds_count{status="200"}`
- `http_server_requests_seconds_sum{routeTemplate="/api/v1/users"}`

### 业务指标

- `ljwx_cache_hits_total{cache_name="permissions"}` - 缓存命中数
- `ljwx_cache_misses_total{cache_name="permissions"}` - 缓存未命中数

**注意**: 租户维度指标通过 Loki 日志查询,不写入 Prometheus,避免高基数问题。

---

## TenantMetricsFilter

```java
@Component
public class TenantMetricsFilter extends OncePerRequestFilter {

    private final MeterRegistry meterRegistry;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                   HttpServletResponse response,
                                   FilterChain filterChain) {
        long startTime = System.currentTimeMillis();
        try {
            filterChain.doFilter(request, response);
        } finally {
            long duration = System.currentTimeMillis() - startTime;
            Long tId = TenantContext.getTenantId();

            // 记录租户请求量（写入 Loki JSON 字段，不写 Prometheus label）
            // 注意: t_id/path 作为 JSON 字段写入日志，禁止作为高基数 Prometheus label
            log.info("tenant_request t_id={} path={} duration={}ms",
                    tId, request.getRequestURI(), duration);

            // 记录全局指标（写入 Prometheus）
            // 禁止将租户 ID 作为 label（高基数，违反 observability.yml 黑名单）
            // 租户维度数据通过上方的 Loki 日志字段查询聚合
            Counter.builder("http_requests_total")
                   .tag("status", String.valueOf(response.getStatus()))
                   .register(meterRegistry)
                   .increment();
        }
    }
}
```

---

## ServiceMonitor 配置

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ljwx-platform
  namespace: ljwx
spec:
  selector:
    matchLabels:
      app: ljwx-platform
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
```

---

## 告警规则

### PrometheusRule

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ljwx-platform-alerts
spec:
  groups:
  - name: ljwx-platform
    rules:
    - alert: HighErrorRate
      expr: |
        sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
        /
        sum(rate(http_server_requests_seconds_count[5m]))
        > 0.01
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected (>1%)"
    - alert: HighMemoryUsage
      expr: jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} > 0.9
      for: 5m
      labels:
        severity: warning
```

---

## 业务规则

- **BL-36-01**：全局指标 → 写入 Prometheus → 低基数
- **BL-36-02**：租户指标 → 写入 Loki → 通过日志查询
- **BL-36-03**：精确统计 → 写入 PostgreSQL → 用于计费
- **BL-36-04**：指标采集间隔 → 30 秒 → 平衡性能和实时性
- **BL-36-05**：告警规则 → 5 分钟窗口 → 避免误报

---

## 验收条件

- **AC-01**：Prometheus 正常采集指标
- **AC-02**：ServiceMonitor 自动发现服务
- **AC-03**：JVM 和 HTTP 指标正常
- **AC-04**：告警规则正常触发
- **AC-05**：租户指标写入 Loki

---

## 关键约束

- 低基数：Prometheus 指标基数 < 1000
- 租户维度：通过 Loki 日志查询,不写 Prometheus
- 采集间隔：30 秒

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-36-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-36-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-36-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-36-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-36-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-36-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-36-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-36-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-36-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-36-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
