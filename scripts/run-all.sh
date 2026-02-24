#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# run-all.sh — 全量执行器（Phase 0–27，幂等，可中断续跑）
#
# 用法:
#   bash scripts/run-all.sh              # 执行所有未完成的 Phase
#   bash scripts/run-all.sh --from 5     # 从 Phase 5 开始
#   bash scripts/run-all.sh --only 3     # 只执行 Phase 3
#   bash scripts/run-all.sh --dry-run    # 显示执行计划但不执行
#
# 幂等性: 检查 PHASE_MANIFEST.txt 中已完成的 Phase，跳过重复执行
# 追溯性: 每个 Phase 的日志保存在 logs/phase-NN/
#
# Phase 概览:
#   0-5   基础设施（骨架、Core、Data、Security、Web、App）
#   6-10  功能模块（文档、Quartz、字典配置、日志通知文件、首页契约）
#   11-14 前端（Shared 包、Admin 脚手架、Mobile、Screen）
#   15-17 Admin 功能页面（用户角色租户 / 任务字典配置 / 日志文件公告）
#   18-19 集成测试 + 最终 Gate
#   20    菜单管理 + 动态路由
#   21    部门管理 + 数据权限
#   22    个人中心 + 登录日志 + 在线用户（后端）
#   23    Admin 前端页面 Batch 2（菜单/部门/个人中心/登录日志/在线用户）
#   24    租户套餐 + 通知已读 + 导入导出
#   25    系统监控 + API 限流 + WebSocket
#   26    集成测试（Phase 20-25 新功能）
#   27    最终 Gate + 全量 Manifest v2
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

# ── Argument parsing ───────────────────────────────────────
FROM_PHASE=0
ONLY_PHASE=""
DRY_RUN=false
TOTAL_PHASES=28   # Phase 0–27

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)    FROM_PHASE="$2"; shift 2 ;;
    --only)    ONLY_PHASE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# ── Setup ──────────────────────────────────────────────────
mkdir -p logs
MANIFEST="PHASE_MANIFEST.txt"
FAILED_LOG="logs/failed.log"
RUN_LOG="logs/run-all-$(date +%Y%m%d-%H%M%S).log"

: > "$FAILED_LOG"

# ── Helper functions ───────────────────────────────────────
is_completed() {
  local phase="$1"
  [[ -f "$MANIFEST" ]] || return 1
  awk -v p="## PHASE $phase" '
    $0 == p { found=1; next }
    found && /^## PHASE / { exit }
    found && /Status: PASSED/ { print; exit }
  ' "$MANIFEST" | grep -q "Status: PASSED"
}

phase_exists() {
  local phase="$1"
  local padded
  padded=$(printf '%02d' "$phase")
  [[ -f "spec/phase/phase-${padded}.md" ]]
}

# ── Pre-flight ─────────────────────────────────────────────
echo "════════════════════════════════════════════════════"
echo "  LJWX Platform — Full Generation Run"
echo "  Start: $(date)"
echo "  Phases: $FROM_PHASE – $((TOTAL_PHASES - 1))"
[[ -n "$ONLY_PHASE" ]] && echo "  Mode: only Phase $ONLY_PHASE"
$DRY_RUN && echo "  Mode: DRY RUN"
echo "════════════════════════════════════════════════════"
echo ""

if ! $DRY_RUN; then
  echo "--- Preflight Check ---"
  bash scripts/preflight/preflight-check.sh
  echo ""
fi

# ── Determine phase list ───────────────────────────────────
if [[ -n "$ONLY_PHASE" ]]; then
  PHASE_LIST=("$ONLY_PHASE")
else
  PHASE_LIST=()
  for i in $(seq "$FROM_PHASE" $((TOTAL_PHASES - 1))); do
    if phase_exists "$i"; then
      PHASE_LIST+=("$i")
    fi
  done
fi

# ── Execution plan ─────────────────────────────────────────
PASSED=0
FAILED=0
SKIPPED=0

echo "Execution plan (${#PHASE_LIST[@]} phases):"
for phase in "${PHASE_LIST[@]}"; do
  padded=$(printf '%02d' "$phase")
  brief="spec/phase/phase-${padded}.md"
  title=$(grep -m1 '^title:' "$brief" 2>/dev/null | sed 's/title:[[:space:]]*//' | tr -d '"' || echo "?")
  if is_completed "$phase"; then
    echo "  Phase $phase — $title  [ALREADY DONE — will skip]"
  else
    echo "  Phase $phase — $title"
  fi
done
echo ""

$DRY_RUN && echo "Dry run complete." && exit 0

# ── Main execution loop ────────────────────────────────────
for phase in "${PHASE_LIST[@]}"; do
  padded=$(printf '%02d' "$phase")

  echo ""
  echo ">>>>>>>>>> Phase $phase <<<<<<<<<<"

  # Idempotency check
  if is_completed "$phase"; then
    echo "  Phase $phase already completed — skipping."
    SKIPPED=$((SKIPPED + 1))
    PASSED=$((PASSED + 1))
    continue
  fi

  # Detect parallel-eligible phase (both backend and frontend)
  PHASE_BRIEF="spec/phase/phase-${padded}.md"
  YAML_BLOCK=$(awk '/^---$/{n++;if(n==1){next};if(n==2){exit}} n==1{print}' "$PHASE_BRIEF")
  T_BE=$(echo "$YAML_BLOCK" | grep 'backend:' | awk '{print $2}' | head -1)
  T_FE=$(echo "$YAML_BLOCK" | grep 'frontend:' | awk '{print $2}' | head -1)

  EXECUTOR="scripts/phase-execute.sh"
  if [[ "${T_BE:-false}" == "true" && "${T_FE:-false}" == "true" ]]; then
    EXECUTOR="scripts/phase-parallel.sh"
  fi

  LOG_BASE="logs/phase-${padded}"
  mkdir -p "$LOG_BASE"

  # Execute
  if bash "$EXECUTOR" "$phase" "--skip-preflight" 2>&1 | tee "$LOG_BASE/run.log"; then
    echo "Phase $phase — PASSED"
    PASSED=$((PASSED + 1))
  else
    EXIT_CODE=$?
    echo "Phase $phase — FAILED (exit $EXIT_CODE)"
    echo "Phase $phase FAILED — $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$FAILED_LOG"
    FAILED=$((FAILED + 1))
    echo "Continuing to next phase..."
  fi
done

# ── Summary ────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════"
echo "  LJWX Platform — Generation Complete"
echo "  End: $(date)"
echo "  Total: ${#PHASE_LIST[@]} | Passed: $PASSED | Failed: $FAILED | Skipped: $SKIPPED"
if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo "  FAILED phases:"
  cat "$FAILED_LOG"
fi
echo "  Logs: logs/"
echo "════════════════════════════════════════════════════"

exit "$FAILED"
