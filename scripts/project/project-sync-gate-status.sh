#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/project/_lib.sh
source "$SCRIPT_DIR/_lib.sh"

DRY_RUN=true
PROJECT_ID=""
PHASE=""
STATUS=""
ISSUE_NUM=""
OWNER=""
REPO=""

usage() {
  cat <<USAGE
Usage: scripts/project/project-sync-gate-status.sh [options]

Options:
  --phase <0..32>                Phase number
  --status <PASS|FAIL|PENDING|SKIP>
  --issue <number>               Optional explicit issue number
  --project-id <PVT_...>         Optional project id override
  --dry-run                      Dry run (default)
  --apply                        Execute update
  -h, --help                     Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="${2:?missing value}"; shift 2 ;;
    --status) STATUS="${2:?missing value}"; shift 2 ;;
    --issue) ISSUE_NUM="${2:?missing value}"; shift 2 ;;
    --project-id) PROJECT_ID="${2:?missing value}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --apply) DRY_RUN=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

ensure_tools
[[ "$PHASE" =~ ^[0-9]{1,2}$ ]] || die "--phase must be 0..32"
STATUS="$(upper "$STATUS")"
[[ "$STATUS" =~ ^(PASS|FAIL|PENDING|SKIP)$ ]] || die "--status invalid"

if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID="$(project_id_from_cache || true)"
fi

if mapfile -t rr < <(resolve_repo); then
  OWNER="${rr[0]}"
  REPO="${rr[1]}"
fi

if [[ -z "$ISSUE_NUM" ]]; then
  label="phase-$(printf '%02d' "$PHASE")"
  q='query($owner:String!, $repo:String!, $labels:[String!]){ repository(owner:$owner,name:$repo){ issues(first:50, states:OPEN, labels:$labels){ nodes { number title } } } }'
  candidates="$(gh api graphql -f query="$q" -F owner="$OWNER" -F repo="$REPO" -f labels[]="$label" | jq -r --arg p "$(printf '%02d' "$PHASE")" '.data.repository.issues.nodes[] | select(.title|test("^\\[Phase " + $p + "\\]")) | .number')"
  count="$(printf '%s\n' "$candidates" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$count" == "1" ]]; then
    ISSUE_NUM="$(printf '%s\n' "$candidates" | head -n1)"
  elif [[ "$count" == "0" ]]; then
    die "no open phase issue matched phase-$PHASE and title ^[Phase $(printf '%02d' "$PHASE")]"
  else
    die "multiple issues matched phase-$PHASE; pass --issue explicitly"
  fi
fi

mode="--dry-run"
[[ "$DRY_RUN" == "false" ]] && mode="--apply"

cmd=(bash "$SCRIPT_DIR/project-sync-issue.sh" --issue "$ISSUE_NUM" --phase "$PHASE" --gate "$STATUS" "$mode")
[[ -n "$PROJECT_ID" ]] && cmd+=(--project-id "$PROJECT_ID")
printf 'Running:'
printf ' %q' "${cmd[@]}"
echo
"${cmd[@]}"
