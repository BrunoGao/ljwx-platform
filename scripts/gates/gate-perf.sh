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
    local network_args=()
    local env_args=()

    if [[ -n "${K6_DOCKER_NETWORK:-}" ]]; then
      network_args+=(--network "${K6_DOCKER_NETWORK}")
    elif [[ "$(uname -s)" == "Linux" ]]; then
      network_args+=(--network host)
    fi

    local env_key
    for env_key in \
      BASE_URL LOGIN_PATH \
      TENANT_A_USER TENANT_A_PASS TENANT_B_USER TENANT_B_PASS \
      K6_VUS K6_DURATION PERF_ENDPOINTS; do
      if [[ -n "${!env_key:-}" ]]; then
        env_args+=(-e "${env_key}")
      fi
    done

    docker run --rm -i \
      "${network_args[@]}" \
      "${env_args[@]}" \
      -v "$PROJECT_ROOT:/work" \
      -v /tmp:/tmp \
      -w /work \
      grafana/k6:0.49.0 "$@"
    return
  fi

  echo "k6 is not available and docker fallback is unavailable" >&2
  return 127
}

read_json_number_or_zero() {
  local file="$1"
  local filter="$2"
  local value

  value="$(jq -r "$filter" "$file" 2>/dev/null || true)"
  if [[ -z "$value" || "$value" == "null" || "$value" == "NaN" ]]; then
    echo "0"
    return
  fi

  echo "$value"
}

cd "$PROJECT_ROOT"

case_tmp_dir="${TMP_DIR}/k6"
mkdir -p "$case_tmp_dir"
chmod 777 "$case_tmp_dir"

summary_file="${case_tmp_dir}/perf.summary.$$.json"
raw_file="${case_tmp_dir}/perf.raw.$$.json"
log_file="$(mktemp "${case_tmp_dir}/perf.log.XXXXXX")"
rm -f "$summary_file" "$raw_file"

set +e
run_k6 run \
  --summary-export "$summary_file" \
  --out "json=$raw_file" \
  tests/perf/baseline.js >"$log_file" 2>&1
rc=$?
set -e

checks_passed="$(read_json_number_or_zero "$summary_file" '(.metrics.checks.values.passes // .metrics.checks.passes // 0) | tonumber? // 0 | floor')"
checks_failed="$(read_json_number_or_zero "$summary_file" '(.metrics.checks.values.fails // .metrics.checks.fails // 0) | tonumber? // 0 | floor')"
checks_total=$((checks_passed + checks_failed))
p95="$(read_json_number_or_zero "$summary_file" '(.metrics.http_req_duration.values["p(95)"] // .metrics.http_req_duration["p(95)"] // 0) | tonumber? // 0')"
avg="$(read_json_number_or_zero "$summary_file" '(.metrics.http_req_duration.values.avg // .metrics.http_req_duration.avg // 0) | tonumber? // 0')"

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
  --arg critical "$critical" \
  --arg warnings "$warnings" \
  --arg checks "$checks_total" \
  --arg passed "$checks_passed" \
  --arg failed "$checks_failed" \
  --arg p95_ms "$p95" \
  --arg avg_ms "$avg" \
  --argjson violations "$violations" \
  '{
    id: $id,
    name: $name,
    status: $status,
    critical: ($critical | tonumber? // 0),
    warnings: ($warnings | tonumber? // 0),
    message: $message,
    checks: ($checks | tonumber? // 0),
    passed: ($passed | tonumber? // 0),
    failed: ($failed | tonumber? // 0),
    p95_ms: ($p95_ms | tonumber? // 0),
    avg_ms: ($avg_ms | tonumber? // 0),
    violations: $violations
  }' > "$OUT_JSON"

echo "$OUT_JSON"

if [[ "$status" == "FAIL" ]]; then
  exit 1
fi
