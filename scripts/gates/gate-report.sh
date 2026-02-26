#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq first." >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE="${1:-00}"
TMP_DIR="${2:-/tmp/ljwx-gate-results}"
OUT_DIR="docs/reports/data/phases"
HISTORY_DIR="docs/reports/data/history"
mkdir -p "$OUT_DIR" "$HISTORY_DIR"

if ! [[ "$PHASE" =~ ^[0-9]{2}$ ]]; then
  PHASE="00"
fi

commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
remote="$(git config --get remote.origin.url 2>/dev/null || true)"
owner="unknown"
repo="unknown"
default_branch="master"
if [[ "$remote" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
fi

run_id="${GITHUB_RUN_ID:-local}"
run_attempt="${GITHUB_RUN_ATTEMPT:-1}"
workflow_name="${GITHUB_WORKFLOW:-gate-local}"
run_url=""
if [[ "$owner" != "unknown" && "$repo" != "unknown" && "$run_id" != "local" ]]; then
  run_url="https://github.com/${owner}/${repo}/actions/runs/${run_id}"
fi

artifact_base="data/artifacts/${run_id}/phase-${PHASE}"

tmp_rules="$(mktemp)"
if ls "$TMP_DIR"/R*.json >/dev/null 2>&1; then
  jq -s '.' "$TMP_DIR"/R*.json >"$tmp_rules"
else
  echo '[]' >"$tmp_rules"
fi

summary_json="$(jq -r '
  def count_status($s): map(select(.status == $s)) | length;
  def sum_field($f): map(.[$f] // 0) | add;
  . as $r
  | {
      total: ($r | length),
      pass: count_status("PASS"),
      fail: count_status("FAIL"),
      skip: count_status("SKIP"),
      critical: sum_field("critical"),
      warnings: sum_field("warnings"),
      pass_rate: (if ($r|length) == 0 then 0 else ((count_status("PASS") * 100 / ($r|length)) * 100 | round / 100) end)
    }
' "$tmp_rules")"

status="$(echo "$summary_json" | jq -r 'if .fail > 0 then "FAIL" elif .total == 0 then "PENDING" else "PASS" end')"

violations="$(jq '
  [
    .[] as $r
    | if ($r.status == "FAIL") then
        if (($r.violations // []) | length) > 0 then
          ($r.violations[] | {
            rule: (.rule // $r.id),
            severity: (.severity // "CRITICAL"),
            file: (.file // null),
            line: (.line // null),
            message: (.message // $r.message // "Gate failed")
          })
        else
          {
            rule: $r.id,
            severity: "CRITICAL",
            file: null,
            line: null,
            message: ($r.message // "Gate failed")
          }
        end
      else empty end
  ]
' "$tmp_rules")"

phase_json="$(jq -n \
  --arg phase "$PHASE" \
  --arg status "$status" \
  --arg timestamp "$ts" \
  --arg commit "$commit" \
  --arg branch "$branch" \
  --arg owner "$owner" \
  --arg repo "$repo" \
  --arg default_branch "$default_branch" \
  --arg run_id "$run_id" \
  --arg run_attempt "$run_attempt" \
  --arg workflow_name "$workflow_name" \
  --arg run_url "$run_url" \
  --arg artifact_base "$artifact_base" \
  --slurpfile rules "$tmp_rules" \
  --argjson summary "$summary_json" \
  --argjson violations "$violations" \
  '{
    phase: $phase,
    status: $status,
    timestamp: $timestamp,
    repo: {owner: $owner, name: $repo, default_branch: $default_branch},
    git: {commit: $commit, branch: $branch},
    ci: {
      run_id: (if $run_id == "local" then null else ($run_id | tonumber) end),
      run_attempt: ($run_attempt | tonumber),
      workflow: $workflow_name,
      run_url: (if $run_url == "" then null else $run_url end)
    },
    artifacts: {
      surefire_html: ($artifact_base + "/surefire-index.html"),
      surefire_xml_index: ($artifact_base + "/surefire-index.json"),
      gate_raw_log: ($artifact_base + "/gate.log")
    },
    rules: $rules[0],
    summary: $summary,
    violations: $violations
  }')"

phase_path="$OUT_DIR/phase-$PHASE.json"
printf '%s\n' "$phase_json" >"$phase_path"

safe_ts="$(date -u +%Y%m%dT%H%M%SZ)"
history_path="$HISTORY_DIR/${safe_ts}_phase${PHASE}_${commit}.json"
printf '%s\n' "$phase_json" >"$history_path"

# Retain only newest 200 history files
ls -1t "$HISTORY_DIR"/*.json 2>/dev/null | awk 'NR>200' | xargs -r rm -f

echo "$phase_path"
