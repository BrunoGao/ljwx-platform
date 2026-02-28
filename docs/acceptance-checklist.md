# GHCR-Sync-Harbor 验收清单

## Phase 1 最小可运行链路
- [ ] `build-and-notify.yml` 在 `main/develop` 推送后成功执行。
- [x] backend/admin-ui/screen 三个镜像已推送到 GHCR，并有 `sha-*` 与 `branch-*` 标签。
- [x] GitHub Action 能成功调用 `POST /sync`。
- [x] `sync-service` 可在本地启动，`GET /healthz` 返回 `db_ok=true`。
- [x] 合法 webhook 入库后，任务状态从 `PENDING` 变为 `VERIFIED`。
- [x] Harbor 中能看到对应镜像标签。

## Phase 2 安全与可观测
- [ ] Bearer 错误时 `/sync` 返回 401。
- [ ] HMAC 签名错误时 `/sync` 返回 403。
- [ ] 时间窗超限时 `/sync` 返回 401。
- [x] 重复 `event_id` 不重复入队（返回 `deduplicated=true`）。
- [ ] `GET /metrics` 可被 Prometheus 抓取。
- [ ] 网络故障场景进入 `FAILED_RETRYABLE` 且可指数退避重试。
- [ ] 凭据错误场景进入 `FAILED_FATAL`。

## Phase 3 GitOps 联动
- [ ] deploy 仓库仅引用 Harbor 镜像。
- [ ] 仅 `VERIFIED` 版本允许进入 deploy 仓库变更。
- [ ] ArgoCD/Flux 仅由 deploy 仓库变更触发部署。
- [ ] 回滚可通过切换到历史 `sha-*`（或 digest）快速恢复。

## 手工联调命令
```bash
cd /root/codes/ljwx-platform
export SYNC_WEBHOOK_URL="http://127.0.0.1:8088"
export SYNC_HMAC_SECRET="replace_me"
export SYNC_BEARER_TOKEN="replace_me"
bash scripts/test-webhook.sh
```

## 联调记录（2026-02-28）
- 证书与入口：`sync.eu.lingjingwanxiang.cn` 的证书已就绪（`Certificate Ready=True`），外网可访问 `POST /sync`。
- Workflow 触发与结果：`build-and-notify` run id `22513905159`（`workflow_dispatch`）完成成功，`Build Backend/Admin UI/Screen` 与 `Notify Sync Service` 全部 `success`。
- Sync 入队与执行：本次 workflow 产生三条事件并入库，任务均完成到 `VERIFIED`：
  - backend: `task-dc3d2c53-60e7-40a5-bbf7-63087e2845e8`
  - admin-ui: `task-1a88fddc-0416-4229-bda7-a3ed803fc7e2`
  - screen: `task-bb732c6f-c916-4f20-9720-559d002b456f`
- Harbor 校验：`harbor.eu.lingjingwanxiang.cn/ljwx/{ljwx-platform,ljwx-platform-admin-ui,ljwx-platform-screen}:sha-b7766e9` 可成功 `inspect`，digest 与任务记录一致。
- 去重校验：重复事件请求返回 `deduplicated=true`，未重复入队。
