# Contributing Guide

## Scope

This repository is managed with GitHub Issues, Projects V2, Milestones, and
Conventional Commits. All changes must be traceable from requirement to release.
By submitting a contribution, you also agree to `CLA.md`.

## Contribution Flow

1. Open or link an Issue before code changes.
2. Use a dedicated branch from `main`.
3. Keep commits in Conventional Commits format:
   - `feat(scope): ...`
   - `fix(scope): ...`
   - `refactor(scope): ...`
   - `docs(scope): ...`
   - `test(scope): ...`
   - `chore(scope): ...`
4. Open a Pull Request with:
   - Issue linkage (`Closes #...` or `Relates #...`)
   - phase/spec reference
   - test evidence
5. Require CODEOWNERS review and passing status checks before merge.

## Branching Strategy

- Protected branches: `main`, `master`
- Working branches: `feature/*`, `fix/*`, `chore/*`, `hotfix/*`
- Merge mode: squash or rebase only (linear history)
- Force push to protected branches is forbidden.

## Definition Of Done

A PR is considered ready only when all items are satisfied:

- linked Issue and scope are clear
- CI and gate checks pass
- docs/ADR updated when behavior or architecture changes
- `CHANGELOG.md` updated for user-facing or operational changes
- security impact is reviewed for auth/data/dependency changes

## Code Review Policy

- At least 1 approval is required.
- CODEOWNERS paths require owner approval.
- Reviewer must reject PRs lacking tests for behavior changes.
- Unresolved conversations block merge.

## Security And Secrets

- Never commit credentials, tokens, or private keys.
- Use repository or environment secrets in Actions.
- Report vulnerabilities through `SECURITY.md`.

## CLA

- All contributors must accept `CLA.md`.
- Maintainers may ask external contributors to include:
  `I have read and agree to CLA.md` in PR description.

## Local Validation

Run before opening a PR:

```bash
bash scripts/ci/lint-shell.sh
bash scripts/ci/lint-yaml.sh
mvn -B -ntp -q test -f pom.xml
```

## Project Management Metadata

Use labels and fields consistently:

- labels: `type:*`, `priority:*`, `phase-*`, `workflow:*`
- milestones: `Phase XX`
- project fields: `Phase`, `Workflow`, `Priority`, `Gate Status`
