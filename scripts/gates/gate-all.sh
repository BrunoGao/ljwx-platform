#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-all.sh — 聚合所有 Gate 脚本，按依赖顺序执行
# 任何一个 Gate 失败则整体失败，但全部跑完后才报告汇总
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

GATES=(
  "gate-manifest.sh"
  "gate-rules.sh"
  "gate-compile.sh"
  "gate-integration.sh"
  "gate-contract.sh"
  "gate-nfr.sh"
)

TOTAL=0
PASSED=0
FAILED=0
FAILED_NAMES=()
SKIPPED=0

echo "╔══════════════════════════════════════════════════╗"
echo "║            LJWX Gate — Full Check                ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

for GATE in "${GATES[@]}"; do
  GATE_PATH="scripts/gates/$GATE"
  ((TOTAL++))

  if [[ ! -f "$GATE_PATH" ]]; then
    echo "  SKIP  $GATE (file not found)"
    ((SKIPPED++))
    continue
  fi

  echo "── $GATE ──────────────────────────────────────"
  if bash "$GATE_PATH"; then
    echo "  PASS  $GATE"
    ((PASSED++))
  else
    echo "  FAIL  $GATE"
    ((FAILED++))
    FAILED_NAMES+=("$GATE")
  fi
  echo ""
done

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
