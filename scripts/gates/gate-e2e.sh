#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="${TMP_DIR:-/tmp/ljwx-gate-results}"
mkdir -p "$TMP_DIR"
OUT_JSON="$TMP_DIR/R10.json"

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
    docker run --rm -i \
      -v "$PROJECT_ROOT:/work" \
      -w /work \
      grafana/k6:0.49.0 "$@"
    return
  fi

  echo "k6 is not available and docker fallback is unavailable" >&2
  return 127
}

collect_failed_checks() {
  local summary_file="$1"
  jq -r '
    def walk_groups($g):
      ([($g.checks // [])[] | select((.fails // 0) > 0) | .name]
       + [($g.groups // [])[] | walk_groups(.)] | add);
    (if .root_group then walk_groups(.root_group) else [] end)[]?
  ' "$summary_file" 2>/dev/null || true
}

build_violations_from_checks() {
  local summary_file="$1"
  local script_name="$2"
  local lines
  lines="$(collect_failed_checks "$summary_file")"

  if [[ -z "$lines" ]]; then
    echo '[]'
    return
  fi

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    local severity="WARNING"
    local rule="e2e_check_failed"
    if [[ "$name" == *"tenantB_"* || "$name" == *"cross_tenant"* || "$name" == *"404"* ]]; then
      severity="CRITICAL"
      rule="tenant_isolation_cross_tenant_must_404"
    fi

    jq -nc \
      --arg file "$script_name" \
      --arg rule "$rule" \
      --arg severity "$severity" \
      --arg message "failed check: $name" \
      --arg fix "Ensure cross-tenant access on selectById/updateById/deleteById returns 404 and tenant interceptor applies uniformly." \
      '{file:$file,rule:$rule,severity:$severity,message:$message,fix:$fix}'
  done <<<"$lines" | jq -s '.'
}

build_violations_from_log() {
  local log_file="$1"
  local script_name="$2"
  local rows
  rows="$(grep -E 'expected=404 actual=|tenant isolation violation|ERRO\[|panic|Exception' "$log_file" | head -n 20 || true)"

  if [[ -z "$rows" ]]; then
    echo '[]'
    return
  fi

  while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    local severity="WARNING"
    local rule="e2e_runtime_error"
    if [[ "$row" == *"expected=404 actual="* || "$row" == *"tenant isolation violation"* ]]; then
      severity="CRITICAL"
      rule="tenant_isolation_cross_tenant_must_404"
    fi

    jq -nc \
      --arg file "$script_name" \
      --arg rule "$rule" \
      --arg severity "$severity" \
      --arg message "$row" \
      --arg fix "Validate tenant interceptor coverage for read/write-by-id APIs and map cross-tenant hits to HTTP 404." \
      '{file:$file,rule:$rule,severity:$severity,message:$message,fix:$fix}'
  done <<<"$rows" | jq -s '.'
}

run_case() {
  local id="$1"
  local script="$2"

  local summary_file raw_file log_file
  summary_file="$(mktemp)"
  raw_file="$(mktemp)"
  log_file="$(mktemp)"

  local rc=0
  set +e
  run_k6 run \
    --summary-export "$summary_file" \
    --out "json=$raw_file" \
    "$script" >"$log_file" 2>&1
  rc=$?
  set -e

  local checks_total checks_passed checks_failed p95
  checks_passed="$(jq -r '.metrics.checks.values.passes // 0' "$summary_file" 2>/dev/null || echo 0)"
  checks_failed="$(jq -r '.metrics.checks.values.fails // 0' "$summary_file" 2>/dev/null || echo 0)"
  checks_total=$((checks_passed + checks_failed))
  p95="$(jq -r '.metrics.http_req_duration.values["p(95)"] // 0' "$summary_file" 2>/dev/null || echo 0)"

  local v_checks v_logs
  v_checks="$(build_violations_from_checks "$summary_file" "$script")"
  v_logs="$(build_violations_from_log "$log_file" "$script")"

  jq -nc \
    --arg id "$id" \
    --arg script "$script" \
    --argjson rc "$rc" \
    --argjson checks "$checks_total" \
    --argjson passed "$checks_passed" \
    --argjson failed "$checks_failed" \
    --argjson p95 "$p95" \
    --argjson v_checks "$v_checks" \
    --argjson v_logs "$v_logs" \
    '{id:$id,script:$script,rc:$rc,checks:$checks,passed:$passed,failed:$failed,p95:$p95,violations:($v_checks + $v_logs)}'
}

cd "$PROJECT_ROOT"

case1="$(run_case e2e_01 tests/e2e/e2e-01-auth-rbac.js)"
case2="$(run_case e2e_02 tests/e2e/e2e-02-tenant-isolation.js)"

aggregate="$(jq -nc --argjson a "$case1" --argjson b "$case2" '
  [$a,$b] as $all
  | {
      checks: ($all | map(.checks) | add),
      passed: ($all | map(.passed) | add),
      failed: ($all | map(.failed) | add),
      p95: (($all | map(.p95) | add) / (if ($all|length)==0 then 1 else ($all|length) end)),
      rc_fail: ($all | map(select(.rc != 0)) | length),
      violations: ($all | map(.violations) | add)
    }
')"

checks="$(jq -r '.checks' <<<"$aggregate")"
passed="$(jq -r '.passed' <<<"$aggregate")"
failed="$(jq -r '.failed' <<<"$aggregate")"
p95="$(jq -r '.p95' <<<"$aggregate")"
rc_fail="$(jq -r '.rc_fail' <<<"$aggregate")"
violations="$(jq '.violations' <<<"$aggregate")"

status="PASS"
if [[ "$rc_fail" -gt 0 || "$failed" -gt 0 ]]; then
  status="FAIL"
fi

critical="$(jq '[.[] | select((.severity // "") == "CRITICAL")] | length' <<<"$violations")"
warnings="$(jq '[.[] | select((.severity // "") != "CRITICAL")] | length' <<<"$violations")"

message="R10 e2e checks=${checks} passed=${passed} failed=${failed} p95_ms=$(printf '%.2f' "$p95")"

jq -n \
  --arg id "R10" \
  --arg name "E2E System Tests" \
  --arg status "$status" \
  --arg message "$message" \
  --argjson critical "$critical" \
  --argjson warnings "$warnings" \
  --argjson checks "$checks" \
  --argjson passed "$passed" \
  --argjson failed "$failed" \
  --argjson p95_ms "$p95" \
  --argjson violations "$violations" \
  '{id:$id,name:$name,status:$status,critical:$critical,warnings:$warnings,message:$message,checks:$checks,passed:$passed,failed:$failed,p95_ms:$p95_ms,violations:$violations}' > "$OUT_JSON"

echo "$OUT_JSON"

if [[ "$status" == "FAIL" ]]; then
  exit 1
fi
