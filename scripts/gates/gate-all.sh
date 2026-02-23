#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-all.sh — 聚合所有 Gate 脚本，按依赖顺序执行
# 用法: bash scripts/gates/gate-all.sh [phase-number]
# 任何一个 Gate 失败则整体失败，但全部跑完后才报告汇总
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_ARG="${1:-}"

TOTAL=0
PASSED=0
FAILED=0
FAILED_NAMES=()
SKIPPED=0

echo "╔══════════════════════════════════════════════════╗"
echo "║            LJWX Gate — Full Check                ║"
if [[ -n "$PHASE_ARG" ]]; then
echo "║            Phase: $PHASE_ARG                              ║"
fi
echo "╚══════════════════════════════════════════════════╝"
echo ""

run_gate() {
  local gate="$1"
  shift
  local gate_path="scripts/gates/$gate"
  ((TOTAL++))

  if [[ ! -f "$gate_path" ]]; then
    echo "  SKIP  $gate (file not found)"
    ((SKIPPED++))
    return
  fi

  echo "── $gate ──────────────────────────────────────"
  if bash "$gate_path" "$@"; then
    echo "  PASS  $gate"
    ((PASSED++))
  else
    echo "  FAIL  $gate"
    ((FAILED++))
    FAILED_NAMES+=("$gate")
  fi
  echo ""
}

# gate-manifest needs phase arg to check scope files
run_gate "gate-manifest.sh" $PHASE_ARG
# gate-rules: full-repo scan, no phase arg needed
run_gate "gate-rules.sh"
# gate-compile: reads phase from CLAUDE.md
run_gate "gate-compile.sh"
# gate-integration: only runs if Docker available and tests exist
run_gate "gate-integration.sh"
# gate-contract: only runs if app module exists
run_gate "gate-contract.sh"
# gate-nfr: NFR checks
run_gate "gate-nfr.sh"

echo "══════════════════════════════════════════════════"
echo "  Total: $TOTAL | Passed: $PASSED | Failed: $FAILED | Skipped: $SKIPPED"
if [[ $FAILED -gt 0 ]]; then
  echo "  FAILED GATES: ${FAILED_NAMES[*]}"
  echo "══════════════════════════════════════════════════"
  echo "  GATE RESULT: FAILED"
  exit 1
else
  echo "══════════════════════════════════════════════════"
  echo "  GATE RESULT: PASSED"
  exit 0
fi

