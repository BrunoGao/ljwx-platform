# Grafana 可观测统一视图（日志 + 链路 + 指标）

本文档用于在 `ljwx-platform` 上快速启用并验证统一可观测看板。

## 1. 前置条件

- Grafana 已部署且可访问
- Prometheus / Loki / Tempo 数据源已在 Grafana 中可用
- `ljwx-platform` 服务已接入 OTEL 与结构化日志

## 2. Dashboard 文件

- `k8s/grafana-dashboard-observability.json`
- Dashboard UID：`ljwx-platform-obsv`

看板分区：

- 指标（Prometheus）：QPS、错误率、P95/P99、状态码趋势、接口延迟趋势
- 运行时（Prometheus）：可用性、在线实例、JVM 内存、CPU、Hikari 连接池
- 日志（Loki）：实时日志流、日志级别趋势、错误日志、慢接口日志、按 `trace_id` 过滤日志
- 租户与慢接口（Loki）：租户请求量 Top10、租户耗时 P95（基于结构化日志聚合）
- 链路（Tempo）：`service.name` 维度 Trace 搜索 + 与日志联动排查
- 告警态势（Prometheus）：当前 Firing 告警、错误率趋势、P99 延迟趋势

## 3. 自动部署到 k8s（推荐）

```bash
bash scripts/ops/apply-grafana-observability-dashboard.sh
```

可选环境变量：

- `NAMESPACE`（默认 `monitoring`）
- `CONFIGMAP_NAME`（默认 `ljwx-platform-observability-dashboard`）
- `DASHBOARD_FILE`（默认 `k8s/grafana-dashboard-observability.json`）
- `KEY_NAME`（默认 `ljwx-platform-observability.json`）

脚本会创建/更新 ConfigMap，并打上 `grafana_dashboard=1` 标签，兼容 Grafana Sidecar 自动加载。

注意（Argo CD 托管场景）：

- 若 `monitoring/ljwx-platform-observability-dashboard` 被 Argo CD 托管，手工 `kubectl apply` 会被自动回滚。
- 需同步修改 Argo 真源仓库：`BrunoGaoSZ/ljwx-deploy` 的 `apps/ljwx-platform-observability/base/dashboards/ljwx-platform-observability.json`。

## 4. 手工导入（兜底）

Grafana UI：

1. Dashboards -> Import
2. 上传 `k8s/grafana-dashboard-observability.json`
3. 绑定数据源变量：
   - `DS_PROMETHEUS`
   - `DS_LOKI`
   - `DS_TEMPO`
4. 确认 Dashboard UID 为 `ljwx-platform-obsv`（用于固定链接访问）

## 5. 使用方式（Trace 关联排障）

1. 从接口响应头获取 `X-Trace-Id`
2. 在看板变量 `trace_id` 中粘贴该值
3. 在「按 TraceId 过滤日志」面板查看关联日志
4. 在「Trace 搜索」面板按同一 `service_name` 检索调用链

## 6. 验收命令

```bash
# 1) 检查 ConfigMap
kubectl get cm ljwx-platform-observability-dashboard -n monitoring

# 2) 检查 Loki 是否有日志
kubectl -n monitoring logs deploy/loki --since=5m | tail -n 20

# 3) 检查 Tempo 是否就绪
kubectl -n tracing get svc tempo

# 4) 触发一次后端健康检查，生成日志与指标样本
curl -fsS http://platform-backend.lingjingwanxiang.cn/actuator/health
```

## 7. 一键端到端验收（R10/R11 + Prom/Loki/Tempo）

```bash
bash scripts/check-observability-k3s.sh
```

脚本默认执行：

- R10：`scripts/gates/gate-e2e.sh`
- R11：`scripts/gates/gate-perf.sh`
- Prometheus 断言：请求增量、P95 延迟
- Loki 断言：日志条数、`traceId` 关联日志条数
- Tempo 断言：`/ready`、`spans_received_total`、trace 搜索结果、`service.name` 命中

产物：

- 汇总报告：`/tmp/ljwx-gate-results/observability-e2e.json`
- gate 报告：`/tmp/ljwx-gate-results/R10.json`、`/tmp/ljwx-gate-results/R11.json`
- 运行日志：`/tmp/ljwx-gate-results/observability/`

常用环境变量：

- `SERVICE_NAME`（默认 `ljwx-platform`）
- `APP_NAMESPACE` / `APP_SERVICE`（默认 `ljwx-platform`）
- `RUN_R10` / `RUN_R11`（默认 `1`）
- `K6_VUS_R10` / `K6_ITERATIONS_R10`（默认 `1` / `1`）
- `K6_VUS_R11` / `K6_DURATION_R11`（默认 `3` / `20s`）
- `STRICT_TEMPO_SEARCH`（默认 `1`，设为 `0` 时 Tempo 搜索断言降级为告警，不阻断脚本退出）
