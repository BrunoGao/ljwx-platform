#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUDGET_FILE="$ROOT_DIR/.quality-budget.json"
RTM_FILE="$ROOT_DIR/docs/reports/data/rtm.json"
SUMMARY_FILE="$ROOT_DIR/docs/reports/data/summary.json"

APPLY=false
JSON_OUT=false

usage() {
  cat <<USAGE
Usage: scripts/quality/ratchet.sh [options]

Options:
  --apply       Update floor when current coverage is higher (ratchet up)
  --json        Print JSON summary
  -h, --help    Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --json) JSON_OUT=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "missing jq" >&2; exit 1; }
[[ -f "$BUDGET_FILE" ]] || { echo "missing $BUDGET_FILE" >&2; exit 1; }
[[ -f "$RTM_FILE" ]] || { echo "missing $RTM_FILE" >&2; exit 1; }
[[ -f "$SUMMARY_FILE" ]] || { echo "missing $SUMMARY_FILE" >&2; exit 1; }

covered="$(jq '[.matrix[]? | select((.test_covered // .covered // false) == true)] | length' "$RTM_FILE")"
total="$(jq '[.matrix[]?] | length' "$RTM_FILE")"
if [[ "$total" -eq 0 ]]; then
  echo "rtm total endpoints is 0" >&2
  exit 1
fi

current_rate="$(awk "BEGIN { printf \"%.6f\", ($covered/$total) }")"
floor_rate="$(jq -r '.endpoint_coverage_floor // 0' "$BUDGET_FILE")"

exec_run="$(jq '[.phases[]? | select(.r09_status != "SKIP")] | length' "$SUMMARY_FILE")"
exec_total="$(jq '[.phases[]?] | length' "$SUMMARY_FILE")"
if [[ "$exec_total" -gt 0 ]]; then
  exec_rate="$(awk "BEGIN { printf \"%.6f\", ($exec_run/$exec_total) }")"
else
  exec_rate="0.000000"
fi

status="PASS"
reason=""
if awk "BEGIN { exit !($current_rate + 0.0 < $floor_rate + 0.0) }"; then
  status="FAIL"
  reason="endpoint coverage regressed below ratchet floor"
fi

ratchet_updated=false
new_floor="$floor_rate"
if [[ "$status" == "PASS" ]] && awk "BEGIN { exit !($current_rate + 0.0 > $floor_rate + 0.0) }"; then
  new_floor="$current_rate"
  if [[ "$APPLY" == "true" ]]; then
    tmp="$(mktemp)"
    jq --argjson v "$new_floor" '.endpoint_coverage_floor = $v' "$BUDGET_FILE" > "$tmp"
    mv "$tmp" "$BUDGET_FILE"
    ratchet_updated=true
  fi
fi

if [[ "$JSON_OUT" == "true" ]]; then
  jq -n \
    --arg status "$status" \
    --arg reason "$reason" \
    --argjson covered "$covered" \
    --argjson total "$total" \
    --argjson current_rate "$current_rate" \
    --argjson floor_rate "$floor_rate" \
    --argjson exec_run "$exec_run" \
    --argjson exec_total "$exec_total" \
    --argjson exec_rate "$exec_rate" \
    --argjson ratchet_updated "$ratchet_updated" \
    --argjson new_floor "$new_floor" \
    '{status:$status,reason:$reason,coverage:{covered:$covered,total:$total,current_rate:$current_rate,floor_rate:$floor_rate},tests_execution:{run:$exec_run,total:$exec_total,rate:$exec_rate},ratchet_updated:$ratchet_updated,new_floor:$new_floor}'
else
  echo "quality-ratchet status: $status"
  echo "coverage: $covered/$total (rate=$current_rate, floor=$floor_rate)"
  echo "tests-execution: $exec_run/$exec_total (rate=$exec_rate)"
  if [[ "$ratchet_updated" == "true" ]]; then
    echo "ratchet floor updated to $new_floor"
  elif awk "BEGIN { exit !($current_rate + 0.0 > $floor_rate + 0.0) }"; then
    echo "current coverage is above floor; run with --apply to ratchet up"
  fi
  if [[ "$status" == "FAIL" ]]; then
    echo "reason: $reason"
  fi
fi

[[ "$status" == "PASS" ]]
