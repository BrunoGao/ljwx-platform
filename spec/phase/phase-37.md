---
phase: 37
title: "Grafana 仪表盘与告警 (Grafana Dashboards)"
targets:
  backend: false
  frontend: false
depends_on: [36]
bundle_with: []
scope:
  - "k8s/grafana-dashboard-global.json"
  - "k8s/grafana-dashboard-jvm.json"
  - "k8s/grafana-dashboard-tenant.json"
  - "k8s/grafana-alerting-rules.yaml"
---
# Phase 37 — Grafana 仪表盘与告警

| 项目 | 值 |
|-----|---|
| Phase | 37 |
| 模块 | K8s 配置 |
| Feature | L0-D02-F04 |
| 前置依赖 | Phase 36 (Prometheus 指标) |
| 优先级 | 🔴 **P0 - 生产就绪必需** |

## 读取清单

- `CLAUDE.md`（自动加载）
- `spec/07-devops.md` — §Grafana 配置
- `spec/08-output-rules.md`

---

## 功能概述

**问题**: 无可视化监控面板。

**解决方案**:
1. 全局总览仪表盘
2. JVM 监控仪表盘
3. 租户视图仪表盘
4. 告警规则配置

---

## 仪表盘清单

### 1. 全局总览 (Global Overview)

**面板**:
- 请求量 (QPS)
- 错误率
- P95 延迟
- 活跃租户数
- 在线用户数

**数据源**: Prometheus

---

### 2. JVM 监控 (JVM Metrics)

**面板**:
- 堆内存使用率
- GC 暂停时间
- 线程数
- CPU 使用率
- 类加载数

**数据源**: Prometheus

---

### 3. 租户视图 (Tenant View)

**面板**:
- 租户请求量 Top 10
- 租户错误率 Top 10
- 租户 API 调用明细
- 租户存储用量

**数据源**: Loki + PostgreSQL

---

## 告警规则

### 告警级别

| 级别 | 说明 | 通知渠道 |
|------|------|----------|
| **Critical** | 严重故障 | 钉钉 + 短信 |
| **Warning** | 警告 | 钉钉 |
| **Info** | 信息 | 仅记录 |

### 告警规则清单

| 规则名 | 条件 | 级别 |
|--------|------|------|
| HighErrorRate | 错误率 > 5% (5分钟) | Critical |
| HighMemoryUsage | 堆内存 > 90% (5分钟) | Warning |
| HighGCPause | GC 暂停 > 1s (1分钟) | Warning |
| HighP95Latency | P95 延迟 > 3s (5分钟) | Warning |
| ServiceDown | 服务不可用 (1分钟) | Critical |

---

## 业务规则

- **BL-37-01**：仪表盘自动刷新 → 30 秒间隔
- **BL-37-02**：告警规则 → 5 分钟窗口 → 避免误报
- **BL-37-03**：Critical 告警 → 钉钉 + 短信 → 立即通知
- **BL-37-04**：租户视图 → 按租户 ID 过滤 → 支持多租户监控

---

## 验收条件

- **AC-01**：全局总览仪表盘正常显示
- **AC-02**：JVM 监控仪表盘正常显示
- **AC-03**：租户视图仪表盘正常显示
- **AC-04**：告警规则正常触发
- **AC-05**：钉钉通知正常发送

---

## 关键约束

- 仪表盘刷新间隔：30 秒
- 告警窗口：5 分钟
- Critical 告警：必须通知到人
