# GitHub Projects V2 Playbook

## Project V2 Automation (`gh api graphql`)

This repository provides automation scripts under `scripts/project/`:

- `project-bootstrap.sh`: query Project metadata and cache field/option IDs
- `project-add-issue.sh`: add an Issue to a Project V2 board
- `project-set-fields.sh`: update `Phase` / `Workflow` / `Priority` fields
- `project-sync-issue.sh`: one command to add + update fields

### Prerequisites

- `gh` CLI installed and authenticated: `gh auth login`
- `jq` installed
- Write permission for target Project V2
- For Actions usage, token must have Project write permission
  - Org-level projects often require PAT or fine-grained token with project write scope

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

The returned `id` is your Project Node ID (`PVT_...`).

### Method 2: `gh` CLI (recommended)

```bash
gh api graphql -f query='
query($org:String!, $number:Int!) {
  organization(login:$org) {
    projectV2(number:$number) { id title }
  }
}' -F org='<ORG>' -F number=<NUMBER>
```

After getting ID:

```bash
bash scripts/project/project-bootstrap.sh --project-id <PVT_...> --apply
```

## Bootstrap Field Cache

`project-bootstrap.sh` writes `.github/projectv2/project.json` used by later scripts.

```bash
bash scripts/project/project-bootstrap.sh --project-id <PVT_...> --apply
# or
bash scripts/project/project-bootstrap.sh --project-url https://github.com/orgs/<ORG>/projects/<NUMBER> --apply
```

Expected required fields in the Project:

- `Phase` (Number)
- `Workflow` (Single-select): `Brief/Spec/Coding/Gate/Review/Done`
- `Priority` (Single-select): `P0/P1/P2`

If missing, create them in Project UI first, then rerun bootstrap.

## Sync One Issue To Project

Dry-run by default:

```bash
bash scripts/project/project-sync-issue.sh --issue 123
```

Apply changes:

```bash
bash scripts/project/project-sync-issue.sh \
  --issue 123 \
  --phase 20 \
  --workflow Spec \
  --priority P1 \
  --apply
```

Using issue URL:

```bash
bash scripts/project/project-sync-issue.sh \
  --issue-url https://github.com/<OWNER>/<REPO>/issues/123 \
  --apply
```

Value resolution priority:

1. CLI flags (`--phase/--workflow/--priority`)
2. Issue title/body patterns (`[Phase 20]`, `Phase: 20`, `Workflow: Spec`, `Priority: P1`)
3. Labels (`phase-20`, `workflow:spec`, `priority:P1`)

## Common Errors And Troubleshooting

- Permission denied / GraphQL forbidden
  - Confirm `gh auth status`
  - Check account role on org/user project
  - In CI, use token with project write permission
- Field not found (`Phase` / `Workflow` / `Priority`)
  - Create missing field in Project V2 UI
  - Re-run bootstrap to refresh `.github/projectv2/project.json`
- Option mismatch (e.g. `workflow` not recognized)
  - Check exact option names in Project UI
  - Re-run bootstrap and verify cached `options` map
- Issue already in project
  - This is handled idempotently; script reuses existing item and continues to update fields

## Recommended Team Workflow

1. Project admin runs bootstrap once and commits `.github/projectv2/project.json`
2. CI/developers use `project-sync-issue.sh` for day-to-day updates
3. Re-run bootstrap whenever Project field or option definitions change
