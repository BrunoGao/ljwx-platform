#!/usr/bin/env bash
# gate-all.sh — unified gate runner with JSON outputs
set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq first." >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_INPUT="${1:-}"
TMP_DIR="/tmp/ljwx-gate-results"
mkdir -p "$TMP_DIR"
rm -f "$TMP_DIR"/R*.json

resolve_phase() {
  local p="$1"
  if [[ -n "$p" && "$p" != "all" ]]; then
    if [[ "$p" =~ ^[0-9]{1,2}$ ]]; then
      printf '%02d' "$((10#$p))"
      return
    fi
  fi

  local detected
  detected="$(grep -Eo 'Phase:[[:space:]]*[0-9]+' CLAUDE.md 2>/dev/null | head -n1 | grep -Eo '[0-9]+' || true)"
  if [[ -n "$detected" ]]; then
    printf '%02d' "$((10#$detected))"
  else
    echo "00"
  fi
}

PHASE="$(resolve_phase "$PHASE_INPUT")"
PROFILE="backend"
if ((10#$PHASE >= 10 && 10#$PHASE <= 19)); then
  PROFILE="frontend"
fi
SKIP_HEAVY_GATES="${SKIP_HEAVY_GATES:-false}"

echo "╔══════════════════════════════════════════════════╗"
echo "║            LJWX Gate — Full Check                ║"
echo "║            Phase: $PHASE | Profile: $PROFILE            ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
FAILED_NAMES=()

write_rule_json() {
  local id="$1"
  local name="$2"
  local status="$3"
  local critical="$4"
  local warnings="$5"
  local message="$6"

  jq -n \
    --arg id "$id" \
    --arg name "$name" \
    --arg status "$status" \
    --arg message "$message" \
    --argjson critical "$critical" \
    --argjson warnings "$warnings" \
    '{id:$id,name:$name,status:$status,critical:$critical,warnings:$warnings,message:$message}' \
    >"$TMP_DIR/$id.json"
}

run_rule() {
  local id="$1"
  local name="$2"
  local script="$3"
  local phase_aware="$4"
  local heavy="${5:-false}"

  ((TOTAL++))

  if [[ "$PROFILE" == "frontend" && "$id" != "R01" ]]; then
    echo "── $id $name ──────────────────────────────────────"
    echo "  SKIP  frontend profile only enforces R01"
    ((SKIPPED++))
    write_rule_json "$id" "$name" "SKIP" 0 0 "frontend phase profile skip"
    echo ""
    return
  fi

  if [[ "$SKIP_HEAVY_GATES" == "true" && "$heavy" == "true" ]]; then
    echo "── $id $name ──────────────────────────────────────"
    echo "  SKIP  heavy gate skipped in batch mode"
    ((SKIPPED++))
    write_rule_json "$id" "$name" "SKIP" 0 0 "skipped by SKIP_HEAVY_GATES=true"
    echo ""
    return
  fi

  echo "── $id $name ──────────────────────────────────────"
  if [[ ! -f "$script" ]]; then
    echo "  SKIP  script not found: $script"
    ((SKIPPED++))
    write_rule_json "$id" "$name" "SKIP" 0 0 "script not found"
    echo ""
    return
  fi

  if [[ "$phase_aware" == "true" ]]; then
    if bash "$script" "$PHASE"; then
      echo "  PASS  $script"
      ((PASSED++))
      write_rule_json "$id" "$name" "PASS" 0 0 "passed"
    else
      echo "  FAIL  $script"
      ((FAILED++))
      FAILED_NAMES+=("$id")
      write_rule_json "$id" "$name" "FAIL" 1 0 "failed"
    fi
  else
    if bash "$script"; then
      echo "  PASS  $script"
      ((PASSED++))
      write_rule_json "$id" "$name" "PASS" 0 0 "passed"
    else
      echo "  FAIL  $script"
      ((FAILED++))
      FAILED_NAMES+=("$id")
      write_rule_json "$id" "$name" "FAIL" 1 0 "failed"
    fi
  fi
  echo ""
}

run_rule "R01" "Compile" "scripts/gates/gate-compile.sh" "false"
run_rule "R02" "Manifest" "scripts/gates/gate-manifest.sh" "true"
run_rule "R03" "Rules" "scripts/gates/gate-rules.sh" "false"
run_rule "R04" "Flyway Governance" "scripts/gates/gate-flyway-governance.sh" "false"
run_rule "R05" "Integration" "scripts/gates/gate-integration.sh" "false" "true"
run_rule "R06" "Contract" "scripts/gates/gate-contract.sh" "false" "true"
run_rule "R07" "NFR" "scripts/gates/gate-nfr.sh" "false"

# R08: RTM generation (post-summary traceability)
((TOTAL++))
echo "── R08 RTM ──────────────────────────────────────"
if bash scripts/gen-rtm.sh >/dev/null 2>&1; then
  echo "  PASS  scripts/gen-rtm.sh"
  ((PASSED++))
  write_rule_json "R08" "RTM" "PASS" 0 0 "rtm generated"
else
  echo "  FAIL  scripts/gen-rtm.sh"
  ((FAILED++))
  FAILED_NAMES+=("R08")
  write_rule_json "R08" "RTM" "FAIL" 1 0 "rtm generation failed"
fi
echo ""

run_rule "R09" "Tests" "scripts/gates/gate-test.sh" "true" "true"

if [[ -x "scripts/reports/collect-artifacts.sh" ]]; then
  bash scripts/reports/collect-artifacts.sh "$PHASE" >/dev/null 2>&1 || true
fi

phase_report_file="$(bash scripts/gates/gate-report.sh "$PHASE" "$TMP_DIR" 2>/dev/null || true)"
summary_file="$(bash scripts/gates/gate-summary.sh 2>/dev/null || true)"
if [[ -x "scripts/reports/gen-test-report.sh" ]]; then
  bash scripts/reports/gen-test-report.sh >/dev/null 2>&1 || true
fi

if [[ -z "$phase_report_file" || ! -f "$phase_report_file" ]]; then
  fallback="docs/reports/data/phases/phase-$PHASE.json"
  run_id="${GITHUB_RUN_ID:-local}"
  run_url=""
  remote="$(git config --get remote.origin.url 2>/dev/null || true)"
  owner="unknown"
  repo="unknown"
  if [[ "$remote" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  fi
  if [[ "$owner" != "unknown" && "$repo" != "unknown" && "$run_id" != "local" ]]; then
    run_url="https://github.com/${owner}/${repo}/actions/runs/${run_id}"
  fi
  jq -n \
    --arg phase "$PHASE" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg commit "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
    --arg run_id "$run_id" \
    --arg run_url "$run_url" \
    '{phase:$phase,status:"FAIL",timestamp:$ts,git:{commit:$commit,branch:"unknown"},ci:{run_id:(if $run_id=="local" then null else ($run_id|tonumber) end),run_attempt:1,workflow:"gate-local",run_url:(if $run_url=="" then null else $run_url end)},rules:[],summary:{total:0,pass:0,fail:1,skip:0,critical:1,warnings:0,pass_rate:0},violations:[{rule:"SYSTEM",severity:"CRITICAL",file:null,line:null,message:"phase report generation failed"}]}' >"$fallback"
  phase_report_file="$fallback"
fi

if [[ -z "$summary_file" || ! -f "$summary_file" ]]; then
  mkdir -p docs/reports/data
  run_id="${GITHUB_RUN_ID:-local}"
  jq -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg commit "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
    --arg run_id "$run_id" \
    '{generated_at:$ts,repo:{owner:"unknown",name:"unknown",default_branch:"master"},git:{branch:"unknown",commit:$commit,short:$commit},ci:{run_id:(if $run_id=="local" then null else ($run_id|tonumber) end),run_attempt:1,workflow:"gate-local",run_url:null},totals:{pass:0,fail:1,pending:0,critical:1,warnings:0},phases:[],history:[]}' > docs/reports/data/summary.json
fi

echo "══════════════════════════════════════════════════"
echo "  Total: $TOTAL | Passed: $PASSED | Failed: $FAILED | Skipped: $SKIPPED"
echo "  Phase report: $phase_report_file"
echo "  Summary: docs/reports/data/summary.json"
echo "══════════════════════════════════════════════════"

if [[ $FAILED -gt 0 ]]; then
  echo "  FAILED RULES: ${FAILED_NAMES[*]}"
  echo "  GATE RESULT: FAILED"
  echo ""
  echo "📊 Local:  python3 -m http.server 8080 -d docs/reports"
  echo "🌐 Remote: https://<org>.github.io/<repo>/"
  exit 1
fi

echo "  GATE RESULT: PASSED"
echo ""
echo "📊 Local:  python3 -m http.server 8080 -d docs/reports"
echo "🌐 Remote: https://<org>.github.io/<repo>/"
exit 0
