# GHCR-Sync-Harbor 验收清单

## Phase 1 最小可运行链路
- [ ] `build-and-notify.yml` 在 `main/develop` 推送后成功执行。
- [ ] backend/admin-ui/screen 三个镜像已推送到 GHCR，并有 `sha-*` 与 `branch-*` 标签。
- [ ] GitHub Action 能成功调用 `POST /sync`。
- [ ] `sync-service` 可在本地启动，`GET /healthz` 返回 `db_ok=true`。
- [ ] 合法 webhook 入库后，任务状态从 `PENDING` 变为 `VERIFIED`。
- [ ] Harbor 中能看到对应镜像标签。

## Phase 2 安全与可观测
- [ ] Bearer 错误时 `/sync` 返回 401。
- [ ] HMAC 签名错误时 `/sync` 返回 403。
- [ ] 时间窗超限时 `/sync` 返回 401。
- [ ] 重复 `event_id` 不重复入队（返回 `deduplicated=true`）。
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
