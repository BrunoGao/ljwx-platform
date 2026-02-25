# GitHub Native DevEx Setup (Aligned with Current LJWX Deployment)

This guide is optimized for the repository's real workflows today:

- CI workflow: `.github/workflows/ci.yml`
- Deploy workflow: `.github/workflows/release-to-deploy.yml`
- Gate workflow: `.github/workflows/gate-check.yml`

## 1. Bootstrap GitHub resources

Run from repo root:

```bash
bash scripts/setup-github.sh --dry-run --phase-range 20-27
bash scripts/setup-github.sh --apply --phase-range 20-27 \
  --architect-team @BrunoGaoSZ/architects \
  --security-team @BrunoGaoSZ/security \
  --dba-team @BrunoGaoSZ/dba \
  --product-team @BrunoGaoSZ/product
```

Optional milestones:

```bash
bash scripts/setup-github.sh --apply --phase-range 20-27 --init-milestones
```

## 2. Branch Protection (manual in GitHub UI)

Apply protection rules on `master` (and `main` if used):

- Require a pull request before merging
- Require approvals (at least 1)
- Require review from Code Owners
- Require status checks to pass:
  - `Lint`
  - `Backend`
  - `Frontend`
  - `Run Gate Suite`
- Require conversation resolution
- Require linear history
- Block force-push and deletion

## 3. Release and traceability

- `.github/workflows/release.yml` creates GitHub Releases from tags
- `.github/release.yml` controls generated changelog categories by labels
- Keep tag format as: `vX.Y.Z-phaseNN`

## 4. Gate-to-Issue automation

Workflow: `.github/workflows/gate-check.yml`

- Gate key format: `<phase>:<ruleset>:<commit_sha>`
- On `push` to `master/main`:
  - `FAIL`: upsert gate issue with labels (`gate:fail`, `type:gate-fix`, `phase-XX`, `priority:P0`)
  - `PASS`: close matching open issue by exact Gate-Key marker
- Optional Project V2 sync:
  - set repository variable `PROJECT_V2_ID`
  - failed gate issues are added to that Project

## 5. Project V2 setup (manual first)

Recommended fields:

- `Phase` (single select)
- `Priority` (P0/P1/P2)
- `Type` (feature/bugfix/refactor/test/docs/gate-fix)
- `Gate Status` (PASS/FAIL/PENDING)

Recommended views:

- Board: Backlog -> In Progress -> Gate -> Review -> Done
- Table: grouped by phase
- Roadmap: grouped by milestone

## 6. Discussions and Environments

- Enable Discussions categories: RFC, Q&A, Incident Postmortem
- Configure Environments:
  - `staging`
  - `production`
- Set required reviewers and environment secrets for deploy jobs

## 7. GitHub Pages (optional)

If docs publishing is needed:

- Source: `docs/` (or generated static site)
- Protect the publish branch
- Add a dedicated Pages deployment workflow only after content structure is stable

## 8. Runtime Policy (Formal, no emergency defaults)

### Database target

Current production DB target is confirmed as infra PostgreSQL service:

- `jdbc:postgresql://postgres-lb.infra.svc.cluster.local:5432/postgres`

Policy:

- Use infra PostgreSQL service endpoint managed by platform SRE.
- Avoid localhost-style datasource defaults in deployment env for production.
- Keep datasource values in Kubernetes Secret (`ljwx-platform-db`) only.

### Health probes policy

Formal probe policy is strict HTTP health probes (not temporary TCP fallback):

- `liveness`: `/actuator/health/liveness`
- `readiness`: `/actuator/health/readiness`

Application requirements for strict probes:

- Security must allow unauthenticated `/actuator/health/**`.
- Spring Boot health probes must be enabled (`management.endpoint.health.probes.enabled=true`).

### Flyway governance policy

Do not disable Flyway validation in steady state.

- Temporary env `SPRING_FLYWAY_VALIDATE_ON_MIGRATE=false` is emergency-only.
- Migration files `V*.sql` are immutable once applied.
- Gate check `scripts/gates/gate-flyway-governance.sh` enforces immutable checksums via `scripts/gates/flyway-checksums.lock`.

### Emergency rollback cleanup checklist

When new backend image containing strict probe compatibility is promoted:

1. Remove `SPRING_FLYWAY_VALIDATE_ON_MIGRATE=false` from deploy manifests.
2. Restore HTTP probe paths to `/actuator/health/liveness` and `/actuator/health/readiness`.
3. Re-run `acceptance-local-k3s` and require `Synced/Healthy` before closing release.
