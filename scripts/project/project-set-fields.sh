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
OWNER=""
REPO=""

PHASE=""
WORKFLOW=""
PRIORITY=""

usage() {
  cat <<USAGE
Usage: scripts/project/project-set-fields.sh [options]

Input:
  --issue <number>               Issue number
  --issue-url <url>              Issue URL
  --item-id <id>                 Project item ID
  --project-id <PVT_...>         Project ID (optional if cache exists)

Overrides:
  --phase <0..32>
  --workflow <Brief|Spec|Coding|Gate|Review|Done>
  --priority <P0|P1|P2>

Mode:
  --dry-run                      Dry run (default)
  --apply                        Execute updates
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
    --dry-run) DRY_RUN=true; shift ;;
    --apply) DRY_RUN=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

ensure_tools
[[ -f "$CACHE_FILE" ]] || die "missing $CACHE_FILE; run project-bootstrap first"

if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID="$(project_id_from_cache || true)"
fi
[[ -n "$PROJECT_ID" ]] || die "missing project id"

issue_json=""
issue_id=""

if [[ -n "$ISSUE_URL" ]]; then
  if mapfile -t iu < <(issue_number_from_url "$ISSUE_URL"); then
    OWNER="${iu[0]}"; REPO="${iu[1]}"; ISSUE_NUM="${iu[2]}"
  else
    die "invalid issue url: $ISSUE_URL"
  fi
fi

if [[ -n "$ISSUE_NUM" ]]; then
  if [[ -z "$OWNER" || -z "$REPO" ]]; then
    mapfile -t rr < <(resolve_repo)
    OWNER="${rr[0]}"; REPO="${rr[1]}"
  fi
  issue_json="$(query_issue_data "$OWNER" "$REPO" "$ISSUE_NUM")"
  issue_id="$(jq -r '.data.repository.issue.id // empty' <<<"$issue_json")"
  [[ -n "$issue_id" ]] || die "cannot resolve issue id for ${OWNER}/${REPO}#${ISSUE_NUM}"
fi

if [[ -z "$ITEM_ID" ]]; then
  [[ -n "$issue_id" ]] || die "need --item-id or issue context"
  ITEM_ID="$(find_project_item_for_issue "$PROJECT_ID" "$issue_id" || true)"
  [[ -n "$ITEM_ID" ]] || die "issue not found in project; run project-add-issue first"
fi

normalize_workflow() {
  local w
  w="$(trim "$1")"
  case "$(lower "$w")" in
    brief) echo "Brief" ;;
    spec) echo "Spec" ;;
    coding) echo "Coding" ;;
    gate) echo "Gate" ;;
    review) echo "Review" ;;
    done) echo "Done" ;;
    *) echo "" ;;
  esac
}

upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }

normalize_priority() {
  local p
  p="$(trim "$1")"
  case "$(upper "$p")" in
    P0|P1|P2) echo "$(upper "$p")" ;;
    *) echo "" ;;
  esac
}

extract_from_issue() {
  [[ -n "$issue_json" ]] || return 0
  local title body labels
  title="$(jq -r '.data.repository.issue.title // ""' <<<"$issue_json")"
  body="$(jq -r '.data.repository.issue.body // ""' <<<"$issue_json")"
  labels="$(jq -r '.data.repository.issue.labels.nodes[].name // empty' <<<"$issue_json")"

  if [[ -z "$PHASE" ]]; then
    if [[ "$title" =~ [Pp]hase[[:space:]]*[:#-]?[[:space:]]*([0-9]{1,2}) ]]; then
      PHASE="${BASH_REMATCH[1]}"
    elif [[ "$title" =~ \[Phase[[:space:]]+([0-9]{1,2})\] ]]; then
      PHASE="${BASH_REMATCH[1]}"
    elif [[ "$body" =~ [Pp]hase[[:space:]]*:[[:space:]]*([0-9]{1,2}) ]]; then
      PHASE="${BASH_REMATCH[1]}"
    else
      local lph
      lph="$(printf '%s\n' "$labels" | sed -nE 's/^phase-([0-9]{1,2})$/\1/p' | head -n1)"
      [[ -n "$lph" ]] && PHASE="$lph"
    fi
  fi

  if [[ -z "$WORKFLOW" ]]; then
    local lw
    lw="$(printf '%s\n' "$labels" | sed -nE 's/^workflow:(.+)$/\1/p' | head -n1)"
    if [[ -n "$lw" ]]; then
      WORKFLOW="$(normalize_workflow "$lw")"
    elif [[ "$body" =~ [Ww]orkflow[[:space:]]*:[[:space:]]*([A-Za-z]+) ]]; then
      WORKFLOW="$(normalize_workflow "${BASH_REMATCH[1]}")"
    fi
  else
    WORKFLOW="$(normalize_workflow "$WORKFLOW")"
  fi

  if [[ -z "$PRIORITY" ]]; then
    local lp
    lp="$(printf '%s\n' "$labels" | sed -nE 's/^priority:([Pp][0-2])$/\U\1/p' | head -n1)"
    if [[ -n "$lp" ]]; then
      PRIORITY="$lp"
    elif [[ "$body" =~ [Pp]riority[[:space:]]*:[[:space:]]*([Pp][0-2]) ]]; then
      PRIORITY="$(upper "${BASH_REMATCH[1]}")"
    fi
  else
    PRIORITY="$(upper "$PRIORITY")"
  fi
}

extract_from_issue

if [[ -n "$PHASE" ]]; then
  [[ "$PHASE" =~ ^[0-9]{1,2}$ ]] || die "invalid phase: $PHASE"
fi
if [[ -n "$WORKFLOW" ]]; then
  WORKFLOW="$(normalize_workflow "$WORKFLOW")"
  [[ -n "$WORKFLOW" ]] || die "invalid workflow; allowed Brief/Spec/Coding/Gate/Review/Done"
fi
if [[ -n "$PRIORITY" ]]; then
  PRIORITY="$(upper "$PRIORITY")"
  [[ "$PRIORITY" =~ ^P[0-2]$ ]] || die "invalid priority; allowed P0/P1/P2"
fi

[[ -n "$PHASE" || -n "$WORKFLOW" || -n "$PRIORITY" ]] || die "no fields resolved; pass --phase/--workflow/--priority or add parseable labels/body"

PHASE_FIELD_ID="$(field_id_from_cache phase || true)"
WORKFLOW_FIELD_ID="$(field_id_from_cache workflow || true)"
PRIORITY_FIELD_ID="$(field_id_from_cache priority || true)"

if [[ -n "$PHASE" && -z "$PHASE_FIELD_ID" ]]; then die "field 'Phase' not found in cache"; fi
if [[ -n "$WORKFLOW" && -z "$WORKFLOW_FIELD_ID" ]]; then die "field 'Workflow' not found in cache"; fi
if [[ -n "$PRIORITY" && -z "$PRIORITY_FIELD_ID" ]]; then die "field 'Priority' not found in cache"; fi

WORKFLOW_OPTION_ID=""
PRIORITY_OPTION_ID=""
if [[ -n "$WORKFLOW" ]]; then
  WORKFLOW_OPTION_ID="$(option_id_from_cache workflow "$WORKFLOW" || true)"
  [[ -n "$WORKFLOW_OPTION_ID" ]] || die "workflow option not found in cache: $WORKFLOW"
fi
if [[ -n "$PRIORITY" ]]; then
  PRIORITY_OPTION_ID="$(option_id_from_cache priority "$PRIORITY" || true)"
  [[ -n "$PRIORITY_OPTION_ID" ]] || die "priority option not found in cache: $PRIORITY"
fi

echo "Resolved values: phase=${PHASE:-<skip>} workflow=${WORKFLOW:-<skip>} priority=${PRIORITY:-<skip>}"

do_mutation_number() {
  local field_id="$1" num="$2"
  local q='mutation($project:ID!, $item:ID!, $field:ID!, $number:Float!){ updateProjectV2ItemFieldValue(input:{projectId:$project,itemId:$item,fieldId:$field,value:{number:$number}}){ projectV2Item { id } } }'
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] set number field ${field_id}=${num}"
  else
    gh api graphql -f query="$q" -F project="$PROJECT_ID" -F item="$ITEM_ID" -F field="$field_id" -F number="$num" >/dev/null
  fi
}

do_mutation_select() {
  local field_id="$1" opt_id="$2" label="$3"
  local q='mutation($project:ID!, $item:ID!, $field:ID!, $option:String!){ updateProjectV2ItemFieldValue(input:{projectId:$project,itemId:$item,fieldId:$field,value:{singleSelectOptionId:$option}}){ projectV2Item { id } } }'
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] set single-select ${label} field=${field_id} option=${opt_id}"
  else
    gh api graphql -f query="$q" -F project="$PROJECT_ID" -F item="$ITEM_ID" -F field="$field_id" -F option="$opt_id" >/dev/null
  fi
}

[[ -n "$PHASE" ]] && do_mutation_number "$PHASE_FIELD_ID" "$PHASE"
[[ -n "$WORKFLOW" ]] && do_mutation_select "$WORKFLOW_FIELD_ID" "$WORKFLOW_OPTION_ID" "workflow:$WORKFLOW"
[[ -n "$PRIORITY" ]] && do_mutation_select "$PRIORITY_FIELD_ID" "$PRIORITY_OPTION_ID" "priority:$PRIORITY"

if [[ "$DRY_RUN" == "false" ]]; then
  echo "updated item: $ITEM_ID"
fi
