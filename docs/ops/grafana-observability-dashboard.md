# Grafana 可观测统一视图（日志 + 链路 + 指标）

本文档用于在 `ljwx-platform` 上快速启用并验证统一可观测看板。

## 1. 前置条件

- Grafana 已部署且可访问
- Prometheus / Loki / Tempo 数据源已在 Grafana 中可用
- `ljwx-platform` 服务已接入 OTEL 与结构化日志

## 2. Dashboard 文件

- `k8s/grafana-dashboard-observability.json`

看板分区：

- 指标（Prometheus）：QPS、错误率、P95、状态码趋势、接口延迟趋势
- 日志（Loki）：实时日志流、日志级别趋势、按 `trace_id` 过滤日志
- 链路（Tempo）：`service.name` 维度 Trace 搜索 + 与日志联动排查

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

## 4. 手工导入（兜底）

Grafana UI：

1. Dashboards -> Import
2. 上传 `k8s/grafana-dashboard-observability.json`
3. 绑定数据源变量：
   - `DS_PROMETHEUS`
   - `DS_LOKI`
   - `DS_TEMPO`

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
