#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/project/_lib.sh
source "$SCRIPT_DIR/_lib.sh"

DRY_RUN=true
PROJECT_ID=""
ISSUE_NUM=""
ISSUE_URL=""
ITEM_ID=""
PHASE=""
WORKFLOW=""
PRIORITY=""
GATE_STATUS=""
WORKSTREAM=""
SUITE=""

usage() {
  cat <<USAGE
Usage: scripts/project/project-sync-issue.sh [options]

Input:
  --issue <number>               Issue number
  --issue-url <url>              Issue URL
  --item-id <id>                 Existing project item ID (skip add)
  --project-id <PVT_...>         Project ID (optional if cache exists)

Field overrides:
  --phase <0..32>
  --workflow <Brief|Spec|Coding|Gate|Review|Done>
  --priority <P0|P1|P2>
  --gate <PASS|FAIL|PENDING|SKIP>
  --workstream <Baseline|Regression|Coverage|Infra>
  --suite <Security|Tenant|CRUD|OpenAPI|Perf|Other>

Mode:
  --dry-run                      Dry run (default)
  --apply                        Execute add + update
  -h, --help                     Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) ISSUE_NUM="${2:?missing value}"; shift 2 ;;
    --issue-url) ISSUE_URL="${2:?missing value}"; shift 2 ;;
    --item-id) ITEM_ID="${2:?missing value}"; shift 2 ;;
    --project-id) PROJECT_ID="${2:?missing value}"; shift 2 ;;
    --phase) PHASE="${2:?missing value}"; shift 2 ;;
    --workflow) WORKFLOW="${2:?missing value}"; shift 2 ;;
    --priority) PRIORITY="${2:?missing value}"; shift 2 ;;
    --gate|--gate-status) GATE_STATUS="${2:?missing value}"; shift 2 ;;
    --workstream) WORKSTREAM="${2:?missing value}"; shift 2 ;;
    --suite) SUITE="${2:?missing value}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --apply) DRY_RUN=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

ensure_tools

if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID="$(project_id_from_cache || true)"
fi

if [[ -z "$ITEM_ID" ]]; then
  [[ -n "$ISSUE_NUM" || -n "$ISSUE_URL" ]] || die "need --issue/--issue-url when --item-id not provided"
fi

ADD_MODE="--dry-run"
SET_MODE="--dry-run"
if [[ "$DRY_RUN" == "false" ]]; then
  ADD_MODE="--apply"
  SET_MODE="--apply"
fi

if [[ -z "$ITEM_ID" ]]; then
  add_cmd=(bash "$SCRIPT_DIR/project-add-issue.sh" "$ADD_MODE")
  [[ -n "$ISSUE_NUM" ]] && add_cmd+=(--issue "$ISSUE_NUM")
  [[ -n "$ISSUE_URL" ]] && add_cmd+=(--issue-url "$ISSUE_URL")
  [[ -n "$PROJECT_ID" ]] && add_cmd+=(--project-id "$PROJECT_ID")

  if [[ "$DRY_RUN" == "true" ]]; then
    "${add_cmd[@]}"
    ITEM_ID="DRYRUN_ITEM"
  else
    ITEM_ID="$("${add_cmd[@]}")"
    [[ -n "$ITEM_ID" ]] || die "failed to resolve item id"
    info "project item: $ITEM_ID"
  fi
fi

set_cmd=(bash "$SCRIPT_DIR/project-set-fields.sh" "$SET_MODE" --item-id "$ITEM_ID")
[[ -n "$ISSUE_NUM" ]] && set_cmd+=(--issue "$ISSUE_NUM")
[[ -n "$ISSUE_URL" ]] && set_cmd+=(--issue-url "$ISSUE_URL")
[[ -n "$PROJECT_ID" ]] && set_cmd+=(--project-id "$PROJECT_ID")
[[ -n "$PHASE" ]] && set_cmd+=(--phase "$PHASE")
[[ -n "$WORKFLOW" ]] && set_cmd+=(--workflow "$WORKFLOW")
[[ -n "$PRIORITY" ]] && set_cmd+=(--priority "$PRIORITY")
[[ -n "$GATE_STATUS" ]] && set_cmd+=(--gate "$GATE_STATUS")
[[ -n "$WORKSTREAM" ]] && set_cmd+=(--workstream "$WORKSTREAM")
[[ -n "$SUITE" ]] && set_cmd+=(--suite "$SUITE")

"${set_cmd[@]}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] sync completed"
else
  echo "sync completed: item=$ITEM_ID"
fi
