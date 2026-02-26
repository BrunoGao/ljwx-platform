#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/project/_lib.sh
source "$SCRIPT_DIR/_lib.sh"

DRY_RUN=true
PR_NUM=""
OWNER=""
REPO=""
PROJECT_ID=""

usage() {
  cat <<USAGE
Usage: scripts/project/project-sync-pr.sh [options]

Options:
  --pr <number>                  Pull request number
  --project-id <PVT_...>         Project V2 ID override
  --dry-run                      Dry run (default)
  --apply                        Execute updates
  -h, --help                     Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) PR_NUM="${2:?missing value}"; shift 2 ;;
    --project-id) PROJECT_ID="${2:?missing value}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --apply) DRY_RUN=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

ensure_tools
[[ -n "$PR_NUM" ]] || die "--pr is required"

if mapfile -t rr < <(resolve_repo); then
  OWNER="${rr[0]}"
  REPO="${rr[1]}"
fi

q='query($owner:String!, $repo:String!, $number:Int!){ repository(owner:$owner,name:$repo){ pullRequest(number:$number){ body closingIssuesReferences(first:20){nodes{number}} } } }'
pr_json="$(gh api graphql -f query="$q" -F owner="$OWNER" -F repo="$REPO" -F number="$PR_NUM")"

issue_nums="$(jq -r '.data.repository.pullRequest.closingIssuesReferences.nodes[].number // empty' <<<"$pr_json")"

if [[ -z "$issue_nums" ]]; then
  body="$(jq -r '.data.repository.pullRequest.body // ""' <<<"$pr_json")"
  issue_nums="$(grep -Eio '(close[sd]?|fix(e[sd])?|resolve[sd]?|relate[sd]?)\s+#([0-9]+)' <<<"$body" | sed -nE 's/.*#([0-9]+)/\1/p' | sort -u || true)"
fi

if [[ -z "$issue_nums" ]]; then
  warn "no linked issues found in PR #$PR_NUM"
  exit 0
fi

mode="--dry-run"
[[ "$DRY_RUN" == "false" ]] && mode="--apply"

while read -r issue; do
  [[ -z "$issue" ]] && continue
  cmd=(bash "$SCRIPT_DIR/project-sync-issue.sh" --issue "$issue" "$mode")
  [[ -n "$PROJECT_ID" ]] && cmd+=(--project-id "$PROJECT_ID")
  printf 'Syncing linked issue #%s\n' "$issue"
  "${cmd[@]}"
done <<<"$issue_nums"
