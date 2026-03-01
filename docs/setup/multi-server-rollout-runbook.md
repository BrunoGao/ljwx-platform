# LJWX 多服务器实施手册（GHCR -> Harbor -> Deploy -> k3s）

## 目标
- 任何服务器按同一流程交付：
- `ljwx-platform` 提交代码后，自动构建推送 GHCR。
- `sync-service` 自动同步 Harbor，验证通过后自动更新 `ljwx-deploy`。
- ArgoCD 自动同步 `ljwx-deploy` 并完成部署。
- 全程不需要人工处理 PR（启用自动关闭旧 PR 和自动合并）。

## 前置条件
- 已有可用 k3s + ArgoCD + cert-manager。
- Harbor 与 GHCR 均可访问。
- `sync-service` 已部署在 `infra` 命名空间。
- GitHub Token 具备 `repo` 权限，可写 `ljwx-deploy`。

## 一次性初始化

### 1. 配置证书默认签发器
- 参考 [cert-manager-default-issuer-checklist.md](./cert-manager-default-issuer-checklist.md)。
- 至少保证：
- `ClusterIssuer/dnspod-letsencrypt` 存在且 `Ready=True`。
- 所有 Ingress 不再使用 `letsencrypt-prod`。

### 2. 启用 sync-service 自动发布

```bash
cd /root/codes/ljwx-platform
chmod +x scripts/ops/apply-sync-autopr.sh

export GITHUB_TOKEN="<github token with repo scope>"
export DEPLOY_AUTOPR_ENABLED=true
export DEPLOY_AUTOPR_CLOSE_SUPERSEDED_PRS=true
export DEPLOY_AUTOPR_AUTO_MERGE_ENABLED=true
export DEPLOY_AUTOPR_AUTO_MERGE_METHOD=squash
export DEPLOY_REPO_OWNER="BrunoGaoSZ"
export DEPLOY_REPO_NAME="ljwx-deploy"
export DEPLOY_REPO_BASE_BRANCH="main"
export DEPLOY_REPO_FILE_PATH="apps/ljwx-platform/overlays/prod/kustomization.yaml"

bash scripts/ops/apply-sync-autopr.sh
```

### 3. 验收当前服务器状态

```bash
chmod +x scripts/ops/check-sync-autopr.sh
bash scripts/ops/check-sync-autopr.sh
```

## 日常流程（无需人工）
- 开发提交 `ljwx-platform`。
- `build-and-notify` 产出 GHCR 镜像和 digest，调用 `sync-service /sync`。
- Worker 完成 Harbor 同步并 `VERIFIED`。
- 自动创建/更新 deploy PR。
- 同组件历史自动 PR 自动关闭。
- 自动合并最新 PR 到 `ljwx-deploy/main`。
- ArgoCD 自动同步并 rollout。

## 常见异常与处理
- webhook 成功但任务失败：
- 查看 `sync-service` 日志 `kubectl logs -n infra deploy/sync-service --since=30m`。
- 证书不受信任：
- 检查 Ingress annotation issuer 与 `Certificate/Order/Challenge` 状态。
- 自动合并未发生：
- 检查 `DEPLOY_AUTOPR_AUTO_MERGE_ENABLED`，并确认目标仓库分支保护允许该 token 合并。

## 新服务器复制步骤
1. 安装 k3s + ArgoCD + cert-manager + dnspod webhook。
2. 部署 `ljwx-deploy`（ArgoCD App 指向 `main`）。
3. 部署 `sync-service`（包含自动 PR 版本镜像）。
4. 执行 `apply-sync-autopr.sh` 配置 token 与开关。
5. 执行 `check-sync-autopr.sh` 与一次真实 webhook 冒烟。
