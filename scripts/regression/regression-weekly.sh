#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SUMMARY_JSON="$ROOT_DIR/docs/reports/data/summary.json"
RTM_JSON="$ROOT_DIR/docs/reports/data/rtm.json"
PHASE_DIR="$ROOT_DIR/docs/reports/data/phases"

MODE="manual"
DRY_RUN=true
STATUS_OVERRIDE=""
ISSUE_NUMBER=""

usage() {
  cat <<USAGE
Usage: scripts/regression/regression-weekly.sh [options]

Options:
  --mode <post-merge|nightly|manual>    Execution mode (default: manual)
  --status <PASS|FAIL>                  Optional explicit gate status
  --issue <number>                      Optional explicit campaign issue number
  --dry-run                             Print result only (default)
  --apply                               Create/update issue and comment
  -h, --help                            Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:?missing value}"; shift 2 ;;
    --status) STATUS_OVERRIDE="${2:?missing value}"; shift 2 ;;
    --issue) ISSUE_NUMBER="${2:?missing value}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --apply) DRY_RUN=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

for cmd in jq gh; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "missing command: $cmd" >&2; exit 1; }
done

[[ -f "$SUMMARY_JSON" ]] || { echo "missing summary file: $SUMMARY_JSON" >&2; exit 1; }
[[ -f "$RTM_JSON" ]] || { echo "missing rtm file: $RTM_JSON" >&2; exit 1; }
[[ -d "$PHASE_DIR" ]] || { echo "missing phase dir: $PHASE_DIR" >&2; exit 1; }

if [[ ! "$MODE" =~ ^(post-merge|nightly|manual)$ ]]; then
  echo "invalid --mode: $MODE" >&2
  exit 1
fi

upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }
now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
week_key() { date -u +"%G-%V"; }

owner_repo_from_git() {
  local remote owner repo
  remote="$(git -C "$ROOT_DIR" config --get remote.origin.url 2>/dev/null || true)"
  if [[ "$remote" =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    printf '%s\n%s\n' "$owner" "$repo"
    return 0
  fi
  return 1
}

mapfile -t rr < <(owner_repo_from_git || true)
OWNER="${rr[0]:-${GITHUB_REPOSITORY_OWNER:-unknown}}"
REPO="${rr[1]:-${GITHUB_REPOSITORY#*/}}"
if [[ -z "${REPO:-}" ]]; then REPO="unknown"; fi

WEEK="$(week_key)"
TITLE="[Regression] Week-${WEEK}"
GENERATED_AT="$(now_utc)"
COMMIT_FULL="$(jq -r '.git.commit // ""' "$SUMMARY_JSON")"
COMMIT_SHORT="$(jq -r '.git.short // (.git.commit // "" | .[0:7])' "$SUMMARY_JSON")"
BRANCH="$(jq -r '.git.branch // "unknown"' "$SUMMARY_JSON")"
RUN_URL="$(jq -r '.ci.run_url // empty' "$SUMMARY_JSON")"
if [[ -z "$RUN_URL" && -n "${GITHUB_RUN_ID:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
  RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
fi

DASHBOARD_URL="https://${OWNER,,}.github.io/${REPO}/"

TOTAL_FAIL="$(jq -r '.totals.fail // 0' "$SUMMARY_JSON")"
TOTAL_CRITICAL="$(jq -r '.totals.critical_violations // .totals.critical // 0' "$SUMMARY_JSON")"
if [[ -n "$STATUS_OVERRIDE" ]]; then
  GATE_STATUS="$(upper "$STATUS_OVERRIDE")"
else
  if [[ "${TOTAL_FAIL:-0}" -gt 0 ]]; then GATE_STATUS="FAIL"; else GATE_STATUS="PASS"; fi
fi
[[ "$GATE_STATUS" =~ ^(PASS|FAIL)$ ]] || { echo "invalid status: $GATE_STATUS" >&2; exit 1; }

COVERED_COUNT="$(jq '[.matrix[]? | select((.test_covered // .covered // false) == true)] | length' "$RTM_JSON")"
ENDPOINT_TOTAL="$(jq '[.matrix[]?] | length' "$RTM_JSON")"
if [[ "$ENDPOINT_TOTAL" -gt 0 ]]; then
  COVERAGE_RATE="$(awk "BEGIN { printf \"%.2f\", ($COVERED_COUNT/$ENDPOINT_TOTAL)*100 }")"
else
  COVERAGE_RATE="0.00"
fi

R09_EXEC_PHASES="$(jq -s '[.[] | (.rules // .gates // [])[]? | select(.id=="R09" and .status!="SKIP")] | length' "$PHASE_DIR"/phase-*.json 2>/dev/null || echo 0)"
R09_FAIL_PHASES="$(jq -s '[.[] | (.rules // .gates // [])[]? | select(.id=="R09" and .status=="FAIL")] | length' "$PHASE_DIR"/phase-*.json 2>/dev/null || echo 0)"
FAILED_TESTS="$(jq -s '[.[] | (.rules // .gates // [])[]? | select(.id=="R09") | (.failed // 0)] | add // 0' "$PHASE_DIR"/phase-*.json 2>/dev/null || echo 0)"

collect_violation_rows() {
  jq -rs '
    [ .[] as $p
      | ($p.phase // "??") as $phase
      | ($p.violations // [])[]
      | {
          phase: $phase,
          severity: ((.severity // "WARNING") | ascii_upcase),
          rule: (.rule // .id // "UNKNOWN"),
          file: (.file // "unknown"),
          line: (.line // 0),
          message: (.message // "")
        }
    ]
  ' "$PHASE_DIR"/phase-*.json 2>/dev/null
}

VIOLATIONS_JSON="$(collect_violation_rows)"
CUR_KEYS_JSON="$(jq '[.[] | "\(.phase)|\(.rule)|\(.file)|\(.line)"] | unique' <<<"$VIOLATIONS_JSON")"

TOP_RISKS_JSON="$(jq '
  group_by(.rule) | map({
    rule: .[0].rule,
    critical_count: ([.[] | select(.severity=="CRITICAL")] | length),
    count: length,
    phases: ([.[].phase] | unique),
    score: (([.[] | select(.severity=="CRITICAL")] | length) * 10 + length)
  })
  | sort_by(.score) | reverse | .[:5]
' <<<"$VIOLATIONS_JSON")"

find_existing_issue() {
  local out
  out="$(gh issue list --repo "${OWNER}/${REPO}" --state open --limit 100 --search "\"${TITLE}\" in:title" --json number,title,url 2>/dev/null || true)"
  jq -r --arg t "$TITLE" '[.[] | select(.title==$t)][0].number // empty' <<<"$out"
}

create_issue_body() {
  cat <<EOM
Regression weekly campaign for **${WEEK}**.

## Goals
- critical violations = 0
- keep gate stable and trend improving
- improve endpoint coverage and reduce test failures

## SOP
1. Review latest comment metrics and diff.
2. Triage Top Risks and assign owners.
3. Track fixes and link PRs.
4. Re-run and verify trend improves.
EOM
}

extract_last_snapshot_json() {
  local issue="$1"
  local comments raw
  comments="$(gh api "repos/${OWNER}/${REPO}/issues/${issue}/comments?per_page=100" 2>/dev/null || true)"
  raw="$(jq -r '
    [ .[] | select(.body | contains("<summary>snapshot</summary>")) | .body ] | last // ""
  ' <<<"$comments")"
  if [[ -z "$raw" ]]; then
    return 0
  fi
  awk '
    BEGIN{injson=0}
    /^```json[[:space:]]*$/ {injson=1; next}
    /^```[[:space:]]*$/ && injson==1 {exit}
    injson==1 {print}
  ' <<<"$raw"
}

if [[ -z "$ISSUE_NUMBER" ]]; then
  ISSUE_NUMBER="$(find_existing_issue || true)"
fi

PREV_SNAPSHOT=""
if [[ -n "$ISSUE_NUMBER" && "$ISSUE_NUMBER" != "(new)" ]]; then
  PREV_SNAPSHOT="$(extract_last_snapshot_json "$ISSUE_NUMBER" || true)"
fi

if [[ -z "$PREV_SNAPSHOT" ]]; then
  PREV_COVERED=0
  PREV_TOTAL=0
  PREV_FAILED_TESTS=0
  PREV_KEYS_JSON='[]'
  PREV_COMMIT=""
else
  PREV_COVERED="$(jq -r '.coverage.covered // 0' <<<"$PREV_SNAPSHOT" 2>/dev/null || echo 0)"
  PREV_TOTAL="$(jq -r '.coverage.total // 0' <<<"$PREV_SNAPSHOT" 2>/dev/null || echo 0)"
  PREV_FAILED_TESTS="$(jq -r '.tests.failed_tests // 0' <<<"$PREV_SNAPSHOT" 2>/dev/null || echo 0)"
  PREV_KEYS_JSON="$(jq '.violation_keys // []' <<<"$PREV_SNAPSHOT" 2>/dev/null || echo '[]')"
  PREV_COMMIT="$(jq -r '.commit // ""' <<<"$PREV_SNAPSHOT" 2>/dev/null || echo "")"
fi

NEW_KEYS_JSON="$(jq -n --argjson cur "$CUR_KEYS_JSON" --argjson prev "$PREV_KEYS_JSON" '$cur - $prev')"
RESOLVED_KEYS_JSON="$(jq -n --argjson cur "$CUR_KEYS_JSON" --argjson prev "$PREV_KEYS_JSON" '$prev - $cur')"

NEW_KEYS_MD="$(jq -r '.[:10][]? | "- " + .' <<<"$NEW_KEYS_JSON")"
RESOLVED_KEYS_MD="$(jq -r '.[:10][]? | "- " + .' <<<"$RESOLVED_KEYS_JSON")"
[[ -n "$NEW_KEYS_MD" ]] || NEW_KEYS_MD="- none"
[[ -n "$RESOLVED_KEYS_MD" ]] || RESOLVED_KEYS_MD="- none"

if [[ "$PREV_TOTAL" -gt 0 ]]; then
  PREV_COVERAGE_RATE="$(awk "BEGIN { printf \"%.2f\", ($PREV_COVERED/$PREV_TOTAL)*100 }")"
else
  PREV_COVERAGE_RATE="0.00"
fi
COVERAGE_DELTA="$(awk "BEGIN { printf \"%+.2f\", $COVERAGE_RATE-$PREV_COVERAGE_RATE }")"
TEST_FAIL_DELTA=$((FAILED_TESTS - PREV_FAILED_TESTS))
if [[ "$TEST_FAIL_DELTA" -gt 0 ]]; then
  TEST_FAIL_DELTA_STR="+$TEST_FAIL_DELTA"
else
  TEST_FAIL_DELTA_STR="$TEST_FAIL_DELTA"
fi

TOP_RISKS_MD="$(jq -r '
  if length == 0 then
    "- none"
  else
    to_entries[]
    | "- " + (.value.rule|tostring)
      + " | count=" + (.value.count|tostring)
      + " | critical=" + (.value.critical_count|tostring)
      + " | phases=" + ((.value.phases|join(",")))
  end
' <<<"$TOP_RISKS_JSON")"

COMPARE_URL=""
if [[ -n "$PREV_COMMIT" && -n "$COMMIT_FULL" && "$PREV_COMMIT" != "$COMMIT_FULL" && "$OWNER" != "unknown" && "$REPO" != "unknown" ]]; then
  COMPARE_URL="https://github.com/${OWNER}/${REPO}/compare/${PREV_COMMIT}...${COMMIT_FULL}"
fi

SNAPSHOT_JSON="$(jq -n \
  --arg generated "$GENERATED_AT" \
  --arg commit "$COMMIT_FULL" \
  --arg run_url "$RUN_URL" \
  --argjson pass "$(jq '.totals.pass // 0' "$SUMMARY_JSON")" \
  --argjson fail "$(jq '.totals.fail // 0' "$SUMMARY_JSON")" \
  --argjson critical "$TOTAL_CRITICAL" \
  --argjson covered "$COVERED_COUNT" \
  --argjson total "$ENDPOINT_TOTAL" \
  --argjson executed_phases "$R09_EXEC_PHASES" \
  --argjson failed_tests "$FAILED_TESTS" \
  --argjson violation_keys "$CUR_KEYS_JSON" \
  --argjson top_rules "$TOP_RISKS_JSON" \
  '{
    generated: $generated,
    commit: $commit,
    run_url: $run_url,
    totals: {pass:$pass, fail:$fail, critical:$critical},
    coverage: {covered:$covered, total:$total},
    tests: {executed_phases:$executed_phases, failed_tests:$failed_tests},
    violation_keys: $violation_keys,
    top_rules: $top_rules
  }'
)"

COMMENT_MD="$(cat <<EOM
## Regression Weekly Update (${WEEK})

### Header
- Generated (UTC): ${GENERATED_AT}
- Mode: ${MODE}
- Commit: \`${COMMIT_SHORT:-unknown}\` (branch: \`${BRANCH}\`)
- Run URL: ${RUN_URL:-N/A}
- Dashboard: ${DASHBOARD_URL}
$( [[ -n "$COMPARE_URL" ]] && printf -- "- Compare: %s\n" "$COMPARE_URL" )

### Metrics Summary
- Gate overall status: **${GATE_STATUS}**
- Critical violations: **${TOTAL_CRITICAL}**
- Tests (R09): executed phases **${R09_EXEC_PHASES}**, failed phases **${R09_FAIL_PHASES}**, failed tests **${FAILED_TESTS}**
- Endpoint coverage: **${COVERED_COUNT}/${ENDPOINT_TOTAL} (${COVERAGE_RATE}%)**

### Diff Summary (best-effort)
- New violations (Top 10):
${NEW_KEYS_MD}
- Resolved violations (Top 10):
${RESOLVED_KEYS_MD}
- Coverage delta: **${COVERAGE_DELTA}%**
- Tests failure delta: **${TEST_FAIL_DELTA_STR}**

### Top Risks
${TOP_RISKS_MD}

### Quick Links
- Actions run: ${RUN_URL:-N/A}
- Quality dashboard: ${DASHBOARD_URL}
$( [[ -n "$COMPARE_URL" ]] && printf -- "- Compare: %s\n" "$COMPARE_URL" )

<details><summary>snapshot</summary>

\`\`\`json
${SNAPSHOT_JSON}
\`\`\`

</details>
EOM
)"

if [[ -z "$ISSUE_NUMBER" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    ISSUE_NUMBER="(new)"
  else
    issue_url=""
    if ! issue_url="$(gh issue create \
      --repo "${OWNER}/${REPO}" \
      --title "$TITLE" \
      --label "type:test" \
      --label "priority:P1" \
      --label "workflow:review" \
      --body "$(create_issue_body)" 2>/dev/null)"; then
      issue_url="$(gh issue create \
        --repo "${OWNER}/${REPO}" \
        --title "$TITLE" \
        --body "$(create_issue_body)")"
    fi
    ISSUE_NUMBER="$(sed -E 's#.*/([0-9]+)$#\1#' <<<"$issue_url")"
    ISSUE_NUMBER="$(sed -E 's#.*/([0-9]+)$#\1#' <<<"$ISSUE_NUMBER")"
  fi
fi

COMMENT_URL=""
if [[ "$DRY_RUN" == "false" ]]; then
  comment_out="$(gh issue comment "$ISSUE_NUMBER" --repo "${OWNER}/${REPO}" --body "$COMMENT_MD" 2>&1 || true)"
  COMMENT_URL="$(grep -Eo 'https://github.com/[^[:space:]]+/issues/[0-9]+#issuecomment-[0-9]+' <<<"$comment_out" | tail -n1 || true)"

  if [[ ! -f "$ROOT_DIR/.github/projectv2/project.json" ]]; then
    echo "missing .github/projectv2/project.json; run project-bootstrap first" >&2
    exit 1
  fi

  sync_cmd=(bash "$ROOT_DIR/scripts/project/project-sync-issue.sh" --issue "$ISSUE_NUMBER" --workstream Regression --suite Other --priority P1 --gate "$GATE_STATUS" --apply)
  if ! "${sync_cmd[@]}"; then
    echo "project sync failed; verify PROJECT_TOKEN/GH_TOKEN permission" >&2
    exit 1
  fi
fi

echo "issue_number: $ISSUE_NUMBER"
if [[ -n "$COMMENT_URL" ]]; then
  echo "comment_url: $COMMENT_URL"
fi
if [[ "$DRY_RUN" == "true" ]]; then
  echo "----- markdown -----"
  echo "$COMMENT_MD"
fi
