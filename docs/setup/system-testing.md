# System Testing (R10 / R11)

## Scope

- `R10`: E2E system smoke/regression via k6
- `R11`: performance baseline via k6 (observation stage, no hard threshold)

Cross-tenant contract is fixed:

- Cross-tenant `GET/PUT/DELETE` by id MUST return `404`.
- Do not return `403` for cross-tenant resource probing.

## Local Run

本地 system-testing 默认走 k3s 纯交付件路径，不再以 `setup-test-env.sh` / docker-compose 作为主入口。

1. Apply delivery artifacts to local k3s:

```bash
cp .env.k3s.delivery.example .env.k3s.delivery
bash scripts/local/k3s-delivery.sh apply
```

2. Run smoke checks through local port-forward:

```bash
bash scripts/local/k3s-delivery.sh smoke
```

3. Seed fixtures and run `R10`:

```bash
bash scripts/local/k3s-delivery.sh e2e
```

4. Run `R11`:

```bash
bash scripts/local/k3s-delivery.sh perf
```

5. Run the full local system-testing chain:

```bash
bash scripts/local/k3s-delivery.sh system-test
```

6. Delete the local test namespace when finished:

```bash
bash scripts/local/k3s-delivery.sh delete
```

说明：

- `smoke` / `e2e` / `perf` 都通过 `kubectl port-forward` 访问本地 `127.0.0.1`
- `seed` 在集群内启动临时 PostgreSQL client Pod 写入夹具，不依赖本机 Docker 容器
- 若本地端口 `18080/18081/18082` 被占用，可通过环境变量 `BACKEND_LOCAL_PORT` / `ADMIN_LOCAL_PORT` / `SCREEN_LOCAL_PORT` 覆盖

## Legacy Compose Path

如果当前机器没有 k3s，可继续使用 compose 仅做临时调试，但这不再是 system-testing 的标准本地路径。

## Gate Integration

- `scripts/gates/gate-e2e.sh` writes `/tmp/ljwx-gate-results/R10.json`
- `scripts/gates/gate-perf.sh` writes `/tmp/ljwx-gate-results/R11.json`
- `scripts/gates/gate-all.sh` runs `R10` only when `ENABLE_E2E=1`

## CI Strategy

- PR gate: no docker-compose E2E
- Post-merge (`post-merge-e2e.yml`): run `R10` smoke and update weekly campaign
- Nightly (`nightly-regression.yml`): run `R10 + R11`, upload reports, update weekly campaign

## R11 Progressive Policy

1. Observation phase: collect p95/avg only (`R11` pass unless execution error)
2. Alert phase: comment + issue when p95 crosses baseline band
3. Blocking phase: enforce threshold in gate after baseline stabilizes
