#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/project/_lib.sh
source "$SCRIPT_DIR/_lib.sh"

DRY_RUN=true
PROJECT_ID=""
ISSUE_NUM=""
ISSUE_URL=""
OWNER=""
REPO=""

usage() {
  cat <<USAGE
Usage: scripts/project/project-add-issue.sh [options]

Options:
  --issue <number>               Issue number
  --issue-url <url>              Issue URL
  --project-id <PVT_...>         Project V2 node ID (optional if cache exists)
  --dry-run                      Dry run (default)
  --apply                        Execute mutation
  -h, --help                     Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) ISSUE_NUM="${2:?missing value for --issue}"; shift 2 ;;
    --issue-url) ISSUE_URL="${2:?missing value for --issue-url}"; shift 2 ;;
    --project-id) PROJECT_ID="${2:?missing value for --project-id}"; shift 2 ;;
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
[[ -n "$PROJECT_ID" ]] || die "project id missing, pass --project-id or run bootstrap"

if [[ -n "$ISSUE_URL" ]]; then
  if mapfile -t iu < <(issue_number_from_url "$ISSUE_URL"); then
    OWNER="${iu[0]}"
    REPO="${iu[1]}"
    ISSUE_NUM="${iu[2]}"
  else
    die "invalid issue url: $ISSUE_URL"
  fi
else
  [[ -n "$ISSUE_NUM" ]] || die "--issue or --issue-url is required"
fi

if [[ -z "$OWNER" || -z "$REPO" ]]; then
  mapfile -t rr < <(resolve_repo)
  OWNER="${rr[0]}"
  REPO="${rr[1]}"
fi

issue_json="$(query_issue_data "$OWNER" "$REPO" "$ISSUE_NUM")"
issue_id="$(jq -r '.data.repository.issue.id // empty' <<<"$issue_json")"
[[ -n "$issue_id" ]] || die "cannot resolve issue node id for ${OWNER}/${REPO}#${ISSUE_NUM}"

existing_item="$(find_project_item_for_issue "$PROJECT_ID" "$issue_id" || true)"
if [[ -n "$existing_item" ]]; then
  echo "$existing_item"
  exit 0
fi

q='mutation($project:ID!, $content:ID!){ addProjectV2ItemById(input:{projectId:$project,contentId:$content}){ item { id } } }'
if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] would add issue ${OWNER}/${REPO}#${ISSUE_NUM} to project ${PROJECT_ID}"
  echo "[dry-run] issueNodeId=${issue_id}"
  exit 0
fi

result="$(gh api graphql -f query="$q" -F project="$PROJECT_ID" -F content="$issue_id")"
item_id="$(jq -r '.data.addProjectV2ItemById.item.id // empty' <<<"$result")"
[[ -n "$item_id" ]] || die "addProjectV2ItemById failed"
echo "$item_id"
