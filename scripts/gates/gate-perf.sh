#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="${TMP_DIR:-/tmp/ljwx-gate-results}"
mkdir -p "$TMP_DIR"
OUT_JSON="$TMP_DIR/R11.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

run_k6() {
  if command -v k6 >/dev/null 2>&1; then
    k6 "$@"
    return
  fi
  if command -v docker >/dev/null 2>&1; then
    docker run --rm -i -v "$PROJECT_ROOT:/work" -w /work grafana/k6:0.49.0 "$@"
    return
  fi
  echo "k6 is not available and docker fallback is unavailable" >&2
  return 127
}

cd "$PROJECT_ROOT"

summary_file="$(mktemp)"
raw_file="$(mktemp)"
log_file="$(mktemp)"

set +e
run_k6 run \
  --summary-export "$summary_file" \
  --out "json=$raw_file" \
  tests/perf/baseline.js >"$log_file" 2>&1
rc=$?
set -e

checks_passed="$(jq -r '.metrics.checks.values.passes // 0' "$summary_file" 2>/dev/null || echo 0)"
checks_failed="$(jq -r '.metrics.checks.values.fails // 0' "$summary_file" 2>/dev/null || echo 0)"
checks_total=$((checks_passed + checks_failed))
p95="$(jq -r '.metrics.http_req_duration.values["p(95)"] // 0' "$summary_file" 2>/dev/null || echo 0)"
avg="$(jq -r '.metrics.http_req_duration.values.avg // 0' "$summary_file" 2>/dev/null || echo 0)"

status="PASS"
violations='[]'
critical=0
warnings=0

if [[ "$rc" -ne 0 ]]; then
  status="FAIL"
  critical=1
  violations="$(jq -nc --arg file "tests/perf/baseline.js" --arg rule "perf_baseline_execution" --arg severity "CRITICAL" --arg message "k6 perf run failed rc=$rc" --arg fix "Verify test env readiness and endpoint availability before running R11 baseline." '[{file:$file,rule:$rule,severity:$severity,message:$message,fix:$fix}]')"
fi

message="R11 perf baseline (observation) checks=${checks_total} passed=${checks_passed} failed=${checks_failed} p95_ms=$(printf '%.2f' "$p95") avg_ms=$(printf '%.2f' "$avg")"

jq -n \
  --arg id "R11" \
  --arg name "Performance Baseline" \
  --arg status "$status" \
  --arg message "$message" \
  --argjson critical "$critical" \
  --argjson warnings "$warnings" \
  --argjson checks "$checks_total" \
  --argjson passed "$checks_passed" \
  --argjson failed "$checks_failed" \
  --argjson p95_ms "$p95" \
  --argjson avg_ms "$avg" \
  --argjson violations "$violations" \
  '{id:$id,name:$name,status:$status,critical:$critical,warnings:$warnings,message:$message,checks:$checks,passed:$passed,failed:$failed,p95_ms:$p95_ms,avg_ms:$avg_ms,violations:$violations}' > "$OUT_JSON"

echo "$OUT_JSON"

if [[ "$status" == "FAIL" ]]; then
  exit 1
fi
