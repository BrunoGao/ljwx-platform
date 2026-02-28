# cert-manager 默认 Issuer 变更清单（最小版）

## 目标
- 所有新 Ingress 在未显式声明时，默认走 `dnspod-letsencrypt`。
- 禁止继续使用不存在或不允许的 issuer（例如 `letsencrypt-prod`）。

## 1. 设置 cert-manager 默认 ClusterIssuer

为 `cert-manager` Deployment 增加以下参数：

- `--default-issuer-name=dnspod-letsencrypt`
- `--default-issuer-kind=ClusterIssuer`
- `--default-issuer-group=cert-manager.io`

示例（临时热修）：

```bash
kubectl -n cert-manager patch deploy cert-manager --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--default-issuer-name=dnspod-letsencrypt"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--default-issuer-kind=ClusterIssuer"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--default-issuer-group=cert-manager.io"}
]'
kubectl -n cert-manager rollout status deploy/cert-manager
```

注意：若 cert-manager 由 Helm 管理，应把参数固化到 Helm values，避免后续被覆盖。

## 2. 增加策略兜底（推荐）

建议使用 Kyverno/Gatekeeper：

- Mutate：当 Ingress 缺失 `cert-manager.io/cluster-issuer` 时，自动补 `dnspod-letsencrypt`
- Validate：拒绝 `letsencrypt-prod` 等不允许 issuer

## 3. 存量资源巡检与修复

巡检命令：

```bash
kubectl get ingress -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{" issuer="}{.metadata.annotations.cert-manager\.io/cluster-issuer}{"\n"}{end}'
```

建议批量修复所有 `issuer=letsencrypt-prod` 的 Ingress 到 `dnspod-letsencrypt`。

## 4. 验证

```bash
kubectl get clusterissuer
kubectl get certificate -A
kubectl get certificaterequest -A
kubectl get order -A
kubectl get challenge -A
```

域名证书验证：

```bash
echo | openssl s_client -connect <host>:443 -servername <host> 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

