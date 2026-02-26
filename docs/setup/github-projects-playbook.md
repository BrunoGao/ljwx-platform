# GitHub Projects V2 Playbook

## Project V2 Automation (`gh api graphql`)

This repository provides automation scripts under `scripts/project/`:

- `project-bootstrap.sh`: query Project metadata and cache field/option IDs
- `project-add-issue.sh`: add an Issue to a Project V2 board
- `project-set-fields.sh`: update Project fields from issue/body/labels/CLI
- `project-sync-issue.sh`: one command to add + update fields
- `project-sync-pr.sh`: sync linked issues from a PR
- `project-sync-gate-status.sh`: update Gate Status by phase or issue

## Field Model (Required)

Create these Project V2 fields in UI (`Project -> Settings -> Fields`):

- `Phase` (Number)
- `Workflow` (Single-select): `Brief`, `Spec`, `Coding`, `Gate`, `Review`, `Done`
- `Priority` (Single-select): `P0`, `P1`, `P2`
- `Gate Status` (Single-select): `PASS`, `FAIL`, `PENDING`, `SKIP`
- `Workstream` (Single-select): `Baseline`, `Regression`, `Coverage`, `Infra`
- `Suite` (Single-select): `Security`, `Tenant`, `CRUD`, `OpenAPI`, `Perf`, `Other`

Notes:

- `Workstream` and `Suite` are Project fields (source of truth), not labels.
- Labels remain optional for search compatibility (e.g. `suite:security`).

## How To Get Project V2 Node ID

Projects V2 GraphQL APIs require the Project **Node ID** (`PVT_...`) rather than URL.

### Method 1: GitHub UI + GraphQL Explorer

1. Open your Project V2 page
2. Copy URL, for example:
   - `https://github.com/orgs/<ORG>/projects/<NUMBER>`
   - `https://github.com/users/<USER>/projects/<NUMBER>`
3. Open GitHub GraphQL Explorer and run:

```graphql
query {
  organization(login: "<ORG>") {
    projectV2(number: <NUMBER>) { id title }
  }
}
```

For user projects:

```graphql
query {
  user(login: "<USER>") {
    projectV2(number: <NUMBER>) { id title }
  }
}
```

### Method 2: `gh` CLI (recommended)

```bash
gh api graphql -f query='
query($org:String!, $number:Int!) {
  organization(login:$org) {
    projectV2(number:$number) { id title }
  }
}' -F org='<ORG>' -F number=<NUMBER>
```

## Bootstrap Field Cache

`project-bootstrap.sh` writes `.github/projectv2/project.json` used by all sync scripts.

```bash
bash scripts/project/project-bootstrap.sh --project-id <PVT_...> --apply
# or
bash scripts/project/project-bootstrap.sh --project-url https://github.com/orgs/<ORG>/projects/<NUMBER> --apply
```

The cache includes:

- `projectId`
- `fields.Phase/Workflow/Priority/GateStatus/Workstream/Suite`
- `options.Workflow/Priority/GateStatus/Workstream/Suite`

If required fields are missing, bootstrap exits non-zero with creation hints.

## Sync One Issue To Project

Dry-run by default:

```bash
bash scripts/project/project-sync-issue.sh --issue 123
```

Apply with explicit overrides:

```bash
bash scripts/project/project-sync-issue.sh \
  --issue 123 \
  --phase 20 \
  --workflow Spec \
  --priority P1 \
  --gate FAIL \
  --workstream Regression \
  --suite Security \
  --apply
```

Value resolution priority:

1. CLI flags
2. Issue body fields (`Phase:`, `Workflow:`, `Priority:`, `Gate Status:`, `Workstream:`, `Suite:`)
3. Labels (`phase-20`, `workflow:spec`, `priority:P1`, `gate:fail`, `workstream:regression`, `suite:security`)
4. Not resolved => skip that field with warning

## Sync Linked Issues From PR

```bash
bash scripts/project/project-sync-pr.sh --pr 456 --apply
```

The script resolves linked issues from GraphQL `closingIssuesReferences`, then falls back to PR body keywords (`Closes #123`, `Fixes #123`, `Relates #123`).

## Sync Gate Status

Update by explicit issue:

```bash
bash scripts/project/project-sync-gate-status.sh \
  --phase 20 --status PASS --issue 123 --apply
```

Update by phase auto-discovery:

```bash
bash scripts/project/project-sync-gate-status.sh \
  --phase 20 --status FAIL --apply
```

Auto-discovery rule:

- search open issues with label `phase-XX`
- title must match `^[Phase XX]`
- exactly one match required; otherwise exit non-zero to avoid accidental updates

## Views Configuration (Recommended)

Set up these Project views:

- `Board / Workflow`: Group by `Workflow`, sort by `Priority`
- `Table / Gate`: Columns include `Phase`, `Gate Status`, `Workstream`, `Suite`, `Priority`, `Workflow`
- `Roadmap / Campaign`: Use date fields from campaign issues, filter `type:test`
- `Gantt / Infra`: Filter `Workstream=Infra`, group by `Suite`

## Automation

Minimum viable automation:

- `.github/workflows/project-v2-issue-sync.yml`: on `issues` events, run `project-sync-issue.sh --apply`
- `.github/workflows/gate-check.yml`: after gate run, call `project-sync-gate-status.sh` for detected phase

Optional enhancement:

- on `pull_request` events, call `project-sync-pr.sh --apply`
- weekly campaign generator workflow for regression summary

## Full Test Ops SOP

Weekly cadence:

1. Create/refresh a `Test Campaign` issue for the week
2. Open/triage `Test Suite` and `Test Debt` issues by top risks
3. Run regression and attach run URL to `Regression Bug` issues
4. Update `Gate Status` on affected Phase epic issues
5. Close done items and keep unresolved items in next campaign

Issue opening rules:

- Baseline/regression initiative => `test-campaign.yml`
- Focused suite implementation => `test-suite.yml`
- Coverage gap => `test-debt.yml`
- Regression failure => `regression-bug.yml`
- Test infra/report workflow => `tech-task.yml`

## Enable GitHub Actions Auto Sync

Required repository secrets:

- `PROJECT_V2_ID`: your Project V2 Node ID (`PVT_...`)
- `PROJECT_TOKEN` (preferred) or `PROJECT_V2_TOKEN`: token with Project write permission
  - `GITHUB_TOKEN` may be enough for repo project, but often insufficient for org project

Quick setup checklist:

1. Add `PROJECT_V2_ID` and token secret
2. Run bootstrap once and commit `.github/projectv2/project.json`
3. Open or edit any issue and confirm `Project V2 Issue Sync` succeeds
4. Confirm issue appears in Project with fields populated

## Troubleshooting

- Permission denied / GraphQL forbidden
  - Verify token scope and project membership
  - Prefer PAT/fine-grained token for org-level projects
- Field or option missing
  - Create field/option in Project UI
  - Rerun bootstrap and commit updated cache
- Multiple phase issues matched
  - Pass `--issue` explicitly to `project-sync-gate-status.sh`
- No values resolved from issue
  - Provide CLI overrides (`--phase/--workflow/...`) or align issue template/body values
