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
GATE_STATUS=""
WORKSTREAM=""
SUITE=""

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
  --gate <PASS|FAIL|PENDING|SKIP>
  --workstream <Baseline|Regression|Coverage|Infra>
  --suite <Security|Tenant|CRUD|OpenAPI|Perf|Other>

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
  case "$(lower "$(trim "$1")")" in
    brief) echo "Brief" ;;
    spec) echo "Spec" ;;
    coding) echo "Coding" ;;
    gate) echo "Gate" ;;
    review) echo "Review" ;;
    done) echo "Done" ;;
    *) echo "" ;;
  esac
}

normalize_priority() {
  case "$(upper "$(trim "$1")")" in
    P0|P1|P2) echo "$(upper "$(trim "$1")")" ;;
    *) echo "" ;;
  esac
}

normalize_gate() {
  case "$(upper "$(trim "$1")")" in
    PASS|FAIL|PENDING|SKIP) echo "$(upper "$(trim "$1")")" ;;
    *) echo "" ;;
  esac
}

normalize_workstream() {
  case "$(lower "$(trim "$1")")" in
    baseline) echo "Baseline" ;;
    regression) echo "Regression" ;;
    coverage) echo "Coverage" ;;
    infra) echo "Infra" ;;
    *) echo "" ;;
  esac
}

normalize_suite() {
  case "$(lower "$(trim "$1")")" in
    security) echo "Security" ;;
    tenant) echo "Tenant" ;;
    crud) echo "CRUD" ;;
    openapi) echo "OpenAPI" ;;
    perf|performance) echo "Perf" ;;
    other) echo "Other" ;;
    *) echo "" ;;
  esac
}

extract_markdown_section() {
  local body="$1" heading="$2"
  awk -v h="$heading" '
    BEGIN { IGNORECASE = 1; found = 0 }
    $0 ~ "^###[[:space:]]*" h "[[:space:]]*$" { found = 1; next }
    found == 1 {
      if ($0 ~ /^###/) exit
      if ($0 ~ /^[[:space:]]*$/) next
      print $0
      exit
    }
  ' <<<"$body" | sed -E 's/^[-*][[:space:]]*//' | sed 's/[[:space:]]*$//'
}

extract_from_issue() {
  [[ -n "$issue_json" ]] || return 0
  local title body labels val
  title="$(jq -r '.data.repository.issue.title // ""' <<<"$issue_json")"
  body="$(jq -r '.data.repository.issue.body // ""' <<<"$issue_json")"
  labels="$(jq -r '.data.repository.issue.labels.nodes[].name // empty' <<<"$issue_json")"

  if [[ -z "$PHASE" ]]; then
    if [[ "$title" =~ [Pp]hase[[:space:]]*[:#-]?[[:space:]]*([0-9]{1,2}) ]]; then
      PHASE="${BASH_REMATCH[1]}"
    elif [[ "$title" =~ \[Phase[[:space:]]+([0-9]{1,2})\] ]]; then
      PHASE="${BASH_REMATCH[1]}"
    else
      val="$(extract_body_field_value "$body" "Phase" || true)"
      if [[ -z "$val" ]]; then
        val="$(extract_markdown_section "$body" "Phase" || true)"
      fi
      if [[ "$val" =~ ^[0-9]{1,2}$ ]]; then
        PHASE="$val"
      else
        val="$(printf '%s\n' "$labels" | sed -nE 's/^phase-([0-9]{1,2})$/\1/p' | head -n1)"
        if [[ -n "$val" ]]; then
          PHASE="$val"
        fi
      fi
    fi
  fi

  if [[ -z "$WORKFLOW" ]]; then
    val="$(extract_body_field_value "$body" "Workflow" || true)"
    if [[ -z "$val" ]]; then
      val="$(extract_markdown_section "$body" "Workflow" || true)"
    fi
    if [[ -z "$val" ]]; then
      val="$(printf '%s\n' "$labels" | sed -nE 's/^workflow:(.+)$/\1/p' | head -n1)"
    fi
    if [[ -n "$val" ]]; then
      WORKFLOW="$(normalize_workflow "$val")"
    fi
  else
    WORKFLOW="$(normalize_workflow "$WORKFLOW")"
  fi

  if [[ -z "$PRIORITY" ]]; then
    val="$(extract_body_field_value "$body" "Priority" || true)"
    if [[ -z "$val" ]]; then
      val="$(extract_markdown_section "$body" "Priority" || true)"
    fi
    if [[ -z "$val" ]]; then
      val="$(printf '%s\n' "$labels" | sed -nE 's/^priority:([Pp][0-2])$/\1/p' | head -n1)"
    fi
    if [[ -n "$val" ]]; then
      PRIORITY="$(normalize_priority "$val")"
    fi
  else
    PRIORITY="$(normalize_priority "$PRIORITY")"
  fi

  if [[ -z "$GATE_STATUS" ]]; then
    val="$(extract_body_field_value "$body" "Gate Status" || true)"
    if [[ -z "$val" ]]; then
      val="$(extract_markdown_section "$body" "Gate Status" || true)"
    fi
    if [[ -z "$val" ]]; then
      val="$(printf '%s\n' "$labels" | sed -nE 's/^gate:(pass|fail|pending|skip)$/\1/ip' | head -n1)"
    fi
    if [[ -n "$val" ]]; then
      GATE_STATUS="$(normalize_gate "$val")"
    fi
  else
    GATE_STATUS="$(normalize_gate "$GATE_STATUS")"
  fi

  if [[ -z "$WORKSTREAM" ]]; then
    val="$(extract_body_field_value "$body" "Workstream" || true)"
    if [[ -z "$val" ]]; then
      val="$(extract_markdown_section "$body" "Workstream" || true)"
    fi
    if [[ -z "$val" ]]; then
      val="$(printf '%s\n' "$labels" | sed -nE 's/^workstream:(.+)$/\1/p' | head -n1)"
    fi
    if [[ -n "$val" ]]; then
      WORKSTREAM="$(normalize_workstream "$val")"
    fi
  else
    WORKSTREAM="$(normalize_workstream "$WORKSTREAM")"
  fi

  if [[ -z "$SUITE" ]]; then
    val="$(extract_body_field_value "$body" "Suite" || true)"
    if [[ -z "$val" ]]; then
      val="$(extract_markdown_section "$body" "Suite" || true)"
    fi
    if [[ -z "$val" ]]; then
      val="$(printf '%s\n' "$labels" | sed -nE 's/^suite:(.+)$/\1/p' | head -n1)"
    fi
    if [[ -n "$val" ]]; then
      SUITE="$(normalize_suite "$val")"
    fi
  else
    SUITE="$(normalize_suite "$SUITE")"
  fi
}

extract_from_issue

if [[ -n "$PHASE" && ! "$PHASE" =~ ^[0-9]{1,2}$ ]]; then die "invalid phase: $PHASE"; fi
if [[ -n "$WORKFLOW" && -z "$(normalize_workflow "$WORKFLOW")" ]]; then die "invalid workflow value"; fi
if [[ -n "$PRIORITY" && -z "$(normalize_priority "$PRIORITY")" ]]; then die "invalid priority value"; fi
if [[ -n "$GATE_STATUS" && -z "$(normalize_gate "$GATE_STATUS")" ]]; then die "invalid gate status value"; fi
if [[ -n "$WORKSTREAM" && -z "$(normalize_workstream "$WORKSTREAM")" ]]; then die "invalid workstream value"; fi
if [[ -n "$SUITE" && -z "$(normalize_suite "$SUITE")" ]]; then die "invalid suite value"; fi

PHASE_FIELD_ID="$(field_id_from_cache Phase || true)"
WORKFLOW_FIELD_ID="$(field_id_from_cache Workflow || true)"
PRIORITY_FIELD_ID="$(field_id_from_cache Priority || true)"
GATE_FIELD_ID="$(field_id_from_cache GateStatus || true)"
WORKSTREAM_FIELD_ID="$(field_id_from_cache Workstream || true)"
SUITE_FIELD_ID="$(field_id_from_cache Suite || true)"

WORKFLOW_OPTION_ID=""
PRIORITY_OPTION_ID=""
GATE_OPTION_ID=""
WORKSTREAM_OPTION_ID=""
SUITE_OPTION_ID=""

if [[ -n "$WORKFLOW" ]]; then WORKFLOW_OPTION_ID="$(option_id_from_cache Workflow "$WORKFLOW" || true)"; fi
if [[ -n "$PRIORITY" ]]; then PRIORITY_OPTION_ID="$(option_id_from_cache Priority "$PRIORITY" || true)"; fi
if [[ -n "$GATE_STATUS" ]]; then GATE_OPTION_ID="$(option_id_from_cache GateStatus "$GATE_STATUS" || true)"; fi
if [[ -n "$WORKSTREAM" ]]; then WORKSTREAM_OPTION_ID="$(option_id_from_cache Workstream "$WORKSTREAM" || true)"; fi
if [[ -n "$SUITE" ]]; then SUITE_OPTION_ID="$(option_id_from_cache Suite "$SUITE" || true)"; fi

if [[ -n "$WORKFLOW" && -z "$WORKFLOW_OPTION_ID" ]]; then die "workflow option not found: $WORKFLOW"; fi
if [[ -n "$PRIORITY" && -z "$PRIORITY_OPTION_ID" ]]; then die "priority option not found: $PRIORITY"; fi
if [[ -n "$GATE_STATUS" && -z "$GATE_OPTION_ID" ]]; then die "gate status option not found: $GATE_STATUS"; fi
if [[ -n "$WORKSTREAM" && -z "$WORKSTREAM_OPTION_ID" ]]; then die "workstream option not found: $WORKSTREAM"; fi
if [[ -n "$SUITE" && -z "$SUITE_OPTION_ID" ]]; then die "suite option not found: $SUITE"; fi

if [[ -z "$PHASE" && -z "$WORKFLOW" && -z "$PRIORITY" && -z "$GATE_STATUS" && -z "$WORKSTREAM" && -z "$SUITE" ]]; then
  warn "no fields resolved; nothing to update"
  exit 0
fi

echo "Resolved values: phase=${PHASE:-<skip>} workflow=${WORKFLOW:-<skip>} priority=${PRIORITY:-<skip>} gate=${GATE_STATUS:-<skip>} workstream=${WORKSTREAM:-<skip>} suite=${SUITE:-<skip>}"

set_number_field() {
  local field_id="$1" value="$2" label="$3"
  [[ -n "$field_id" ]] || { warn "skip $label: field missing in cache"; return 0; }
  local q='mutation($project:ID!, $item:ID!, $field:ID!, $number:Float!){ updateProjectV2ItemFieldValue(input:{projectId:$project,itemId:$item,fieldId:$field,value:{number:$number}}){ projectV2Item { id } } }'
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] set number ${label}=${value}"
  else
    gh api graphql -f query="$q" -F project="$PROJECT_ID" -F item="$ITEM_ID" -F field="$field_id" -F number="$value" >/dev/null
  fi
}

set_select_field() {
  local field_id="$1" opt_id="$2" label="$3"
  [[ -n "$field_id" ]] || { warn "skip $label: field missing in cache"; return 0; }
  local q='mutation($project:ID!, $item:ID!, $field:ID!, $option:String!){ updateProjectV2ItemFieldValue(input:{projectId:$project,itemId:$item,fieldId:$field,value:{singleSelectOptionId:$option}}){ projectV2Item { id } } }'
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] set single-select ${label} option=${opt_id}"
  else
    gh api graphql -f query="$q" -F project="$PROJECT_ID" -F item="$ITEM_ID" -F field="$field_id" -F option="$opt_id" >/dev/null
  fi
}

if [[ -n "$PHASE" ]]; then
  set_number_field "$PHASE_FIELD_ID" "$PHASE" "Phase"
fi
if [[ -n "$WORKFLOW" ]]; then
  set_select_field "$WORKFLOW_FIELD_ID" "$WORKFLOW_OPTION_ID" "Workflow:$WORKFLOW"
fi
if [[ -n "$PRIORITY" ]]; then
  set_select_field "$PRIORITY_FIELD_ID" "$PRIORITY_OPTION_ID" "Priority:$PRIORITY"
fi
if [[ -n "$GATE_STATUS" ]]; then
  set_select_field "$GATE_FIELD_ID" "$GATE_OPTION_ID" "GateStatus:$GATE_STATUS"
fi
if [[ -n "$WORKSTREAM" ]]; then
  set_select_field "$WORKSTREAM_FIELD_ID" "$WORKSTREAM_OPTION_ID" "Workstream:$WORKSTREAM"
fi
if [[ -n "$SUITE" ]]; then
  set_select_field "$SUITE_FIELD_ID" "$SUITE_OPTION_ID" "Suite:$SUITE"
fi

if [[ "$DRY_RUN" == "false" ]]; then
  echo "updated item: $ITEM_ID"
fi
