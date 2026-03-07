# System Testing (R10 / R11)

## Scope

- `R10`: E2E system smoke/regression via k6
- `R11`: performance baseline via k6 (observation stage, no hard threshold)

Cross-tenant contract is fixed:

- Cross-tenant `GET/PUT/DELETE` by id MUST return `404`.
- Do not return `403` for cross-tenant resource probing.

## Local Run

1. Start test environment:

```bash
bash scripts/setup-test-env.sh up
```

2. Run E2E smoke:

```bash
BASE_URL=http://localhost:8080 bash tests/k6-run.sh e2e-01
BASE_URL=http://localhost:8080 bash tests/k6-run.sh e2e-02
```

3. Run performance baseline:

```bash
BASE_URL=http://localhost:8080 bash tests/k6-run.sh perf-baseline
```

4. Stop environment:

```bash
bash scripts/setup-test-env.sh down
```

## k3s Run (Recommended)

Use the same target topology as production delivery:

```bash
RUN_R10=1 RUN_R11=1 bash scripts/check-observability-k3s.sh
```

Common fast smoke:

```bash
RUN_R10=1 RUN_R11=0 K6_VUS_R10=1 K6_ITERATIONS_R10=1 bash scripts/check-observability-k3s.sh
```

## Gate Integration

- `scripts/gates/gate-e2e.sh` writes `/tmp/ljwx-gate-results/R10.json`
- `scripts/gates/gate-perf.sh` writes `/tmp/ljwx-gate-results/R11.json`
- `scripts/gates/gate-all.sh` runs `R10` only when `ENABLE_E2E=1`

## CI Strategy

- PR gate: no docker-compose E2E
- Post-merge (`post-merge-e2e.yml`): run `R10` smoke on k3s and update weekly campaign
- Nightly (`nightly-regression.yml`): run `R10 + R11` on k3s, upload reports, update weekly campaign
- Local docker-compose flow is kept for developer self-check only, not release acceptance

## R11 Progressive Policy

1. Observation phase: collect p95/avg only (`R11` pass unless execution error)
2. Alert phase: comment + issue when p95 crosses baseline band
3. Blocking phase: enforce threshold in gate after baseline stabilizes
