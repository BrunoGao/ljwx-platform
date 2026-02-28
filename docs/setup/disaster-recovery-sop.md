# 灾备恢复 SOP（云主机重置后全量恢复）

## 背景
- 当前服务器重置后，本地数据会丢失。
- 必须将“代码、配置、运行态数据”拆分并外置，才能稳定恢复。

## 必须持久化的资产
- Git 仓库：
- `ljwx-platform`
- `ljwx-deploy`
- Kubernetes 运行态：
- Secret / ConfigMap / Ingress / cert-manager 资源
- `sync-service` 数据：
- `/data/sync.db`
- Harbor 数据：
- 镜像仓库数据目录或其快照
- 数据库数据：
- PostgreSQL 备份（逻辑备份 + binlog/WAL 方案）

## 备份执行（每日）

```bash
cd /root/codes/ljwx-platform
chmod +x scripts/ops/export-runtime-backup.sh
bash scripts/ops/export-runtime-backup.sh
```

- 备份输出默认在 `/tmp/ljwx-platform-backup/<UTC时间戳>/`。
- 该目录必须同步到异地持久存储（对象存储/NAS/另一台机器）。

## 全新机器恢复步骤
1. 安装基础组件：
- k3s
- cert-manager + dnspod issuer
- ArgoCD
- Harbor（或接入外部 Harbor）
2. 恢复 GitOps：
- 让 ArgoCD 指向 `ljwx-deploy/main` 并同步。
3. 恢复运行配置：
- 从备份恢复关键 Secret/ConfigMap/cert-manager 资源。
4. 恢复 sync-service 状态：
- 将备份的 `sync.db` 放回 `sync-service` 挂载目录。
5. 恢复自动化参数：
- 重新执行 `scripts/ops/apply-sync-autopr.sh`。
6. 做验证：
- `scripts/ops/check-sync-autopr.sh`
- 一次真实 webhook 冒烟。

## 工程化建议（必须）
- 把 cert-manager 参数（默认 issuer）固化到 Helm values。
- 把 `sync-service-env` Secret 纳入 Secret 管理方案（例如 External Secrets + Vault）。
- 把备份脚本纳入 cron 或 CI 定时任务，并设置备份完整性告警。
- 把“恢复演练”纳入月度例行，验证 RTO/RPO。
