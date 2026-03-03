# GitHub Lifecycle Governance (LJWX Platform)

This document defines a complete GitHub-native operating model for LJWX Platform,
covering requirement intake, implementation, release, operations, and compliance.

Current repository baseline is aligned as of 2026-03-03.

## 1. One-Command Bootstrap Entry

Run from repository root:

```bash
# Labels / milestones / CODEOWNERS team placeholders
bash scripts/setup-github.sh --dry-run --phase-range 00-53
bash scripts/setup-github.sh --apply --phase-range 00-53 --init-milestones

# Protected branch policy (main + master)
bash scripts/github/apply-branch-protection.sh --dry-run
bash scripts/github/apply-branch-protection.sh --apply

# Environment bootstrap (staging + production)
bash scripts/github/setup-environments.sh --dry-run
bash scripts/github/setup-environments.sh --apply
```

## 2. Full Lifecycle Map

| Stage | Scope | GitHub capability in this repo |
|------|------|---------------------------------|
| Requirement intake | feedback, proposals | Issue templates + Discussions |
| Requirement management | priority, roadmap | Projects V2 + Labels + Milestones |
| Task decomposition | executable tasks | Sub-issues + task lists |
| Design and decision | architecture and RFC | Discussions RFC template + `docs/adr/` |
| Development | coding workflow | branches + PR template + CODEOWNERS |
| Code quality | review and merge guard | branch protection + required checks |
| Testing | unit/integration/e2e/coverage | CI + gate + E2E + coverage workflow |
| Security | vuln and secret governance | Dependabot + CodeQL + dependency review + secret scan + SBOM |
| Build and delivery | images/packages/release | Actions + GHCR + Releases + tags |
| Environment governance | staged rollout and approvals | GitHub Environments (`staging`, `production`) |
| Version and changes | semantic release visibility | SemVer tags + `CHANGELOG.md` |
| Documentation | implementation/ops docs | `docs/` + optional GitHub Pages |
| Monitoring feedback | production signal return | `production-incident` issue template + postmortem discussion template |
| Team and access | ownership and authorization | Teams + repo roles + CODEOWNERS |
| Compliance | legal and contribution policy | `LICENSE` + `CONTRIBUTING.md` + `CODE_OF_CONDUCT.md` + `SECURITY.md` |

## 3. Branching, PR, and Protection

### Branch strategy

- Protected branches: `main`, `master`
- Development branches: `feature/*`, `fix/*`, `chore/*`, `hotfix/*`
- Keep linear history (squash/rebase)

### Required protection policies

`apply-branch-protection.sh` configures:

- PR required before merge
- minimum approvals (default 1, configurable)
- CODEOWNERS review required
- stale review dismissal
- conversation resolution required
- linear history required
- block force-push and deletion
- required status checks

Default checks in script:

- `Lint`
- `Backend`
- `Frontend`
- `gate`
- `pr-policy`
- `dependency-review`
- `Gitleaks`
- `Backend JaCoCo`

Adjust checks via:

```bash
bash scripts/github/apply-branch-protection.sh \
  --apply \
  --checks "Lint,Backend,Frontend,gate,pr-policy,dependency-review,Gitleaks,Backend JaCoCo,Analyze (java),Analyze (javascript-typescript)"
```

## 4. Security Baseline

### Dependency and code security

- `.github/dependabot.yml`: weekly dependency updates
- `.github/workflows/codeql.yml`: CodeQL static analysis
- `.github/workflows/dependency-review.yml`: PR dependency risk gate
- `.github/workflows/secret-scan.yml`: gitleaks secret scan
- `.github/workflows/sbom.yml`: SPDX SBOM artifact generation
- `.github/workflows/dependabot-auto-merge.yml`: patch update auto-merge (after required checks pass)

### Vulnerability intake

- Private reporting channel in `.github/ISSUE_TEMPLATE/config.yml`
- Process policy in `SECURITY.md`

## 5. Testing and Coverage

### Existing checks

- `.github/workflows/ci.yml`
- `.github/workflows/pr-policy.yml`
- `.github/workflows/gate-check.yml`
- `.github/workflows/post-merge-e2e.yml`
- `.github/workflows/nightly-regression.yml`
- `.github/workflows/governance-drift.yml`

### Coverage

- `ljwx-platform-app/pom.xml` includes JaCoCo plugin
- `.github/workflows/coverage.yml` builds and uploads coverage artifacts
- optional Codecov upload when `CODECOV_TOKEN` is configured
- default thresholds: overall line `>= 40%`, diff line `>= 70%`
- thresholds can be overridden via repository variables:
  - `MIN_LINE_COVERAGE`
  - `MIN_DIFF_COVERAGE`

## 6. Release, Versioning, and Artifacts

- Release workflow: `.github/workflows/release.yml`
- Release note categories: `.github/release.yml`
- Build and push containers to GHCR: `.github/workflows/build-and-notify.yml`
- Deploy queue handoff: `.github/workflows/release-to-deploy.yml`
- Versioning convention: SemVer + repo tagging policy (e.g. `v1.2.3-phase27`)
- Changelog source of truth: `CHANGELOG.md`

## 7. Documentation and Decision Traceability

- Architecture decisions: `docs/adr/`
- Setup and ops runbooks: `docs/setup/`
- Optional static publishing: GitHub Pages from `docs/`
- Discussion templates:
  - `.github/DISCUSSION_TEMPLATE/rfc.yml`
  - `.github/DISCUSSION_TEMPLATE/incident-postmortem.yml`

## 8. Monitoring Feedback Loop

When online alerts are triggered:

1. Open `Production Incident` issue template.
2. Link monitoring URL, impact window, and mitigation.
3. Open postmortem discussion.
4. Track follow-up items via sub-issues and Project fields.

Templates used:

- `.github/ISSUE_TEMPLATE/production-incident.yml`
- `.github/DISCUSSION_TEMPLATE/incident-postmortem.yml`

## 9. Team Access and Ownership

- CODEOWNERS governs review ownership on critical paths.
- Branch protection enforces mandatory review and checks.
- Use GitHub Teams and repository roles for least-privilege access.

## 10. Compliance Files

Repository-level mandatory files:

- `LICENSE`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `CHANGELOG.md`
- `CLA.md`

## 11. Operations Checklist

For each new repository setup or major reset:

1. Run `scripts/setup-github.sh`.
2. Apply branch protection via script.
3. Create `staging` and `production` environments.
4. Add required secrets (repo + environment scoped).
5. Add governance and quality configuration:
   - optional secret: `GOVERNANCE_TOKEN` (read branch protection/environment settings reliably)
   - optional variables: `MIN_LINE_COVERAGE`, `MIN_DIFF_COVERAGE`
6. Validate all security and coverage workflows are green.
7. Confirm Issue/PR templates and Discussions categories are active.

## 12. Runtime Policy (Preserved)

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
