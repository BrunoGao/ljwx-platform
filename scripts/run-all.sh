#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# run-all.sh — 全量执行器（Phase 0–53，幂等，可中断续跑）
#
# 用法:
#   bash scripts/run-all.sh              # 执行所有未完成的 Phase
#   bash scripts/run-all.sh --from 5     # 从 Phase 5 开始
#   bash scripts/run-all.sh --only 3     # 只执行 Phase 3
#   bash scripts/run-all.sh --dry-run    # 显示执行计划但不执行
#
# CI Gate 用法（在指定 Phase 后 push 并等待 GitHub Actions 全绿）:
#   bash scripts/run-all.sh \
#     --checkpoint "5,10,18,27,32,44,53" \
#     --repo your-org/your-repo \
#     --workflow build-and-notify.yml \
#     --auto-commit
#
# 幂等性: 检查 PHASE_MANIFEST.txt 中已完成的 Phase，跳过重复执行
# 追溯性: 每个 Phase 的日志保存在 logs/phase-NN/
#
# Phase 概览:
#   0-5   基础设施（骨架、Core、Data、Security、Web、App）
#   6-10  功能模块（文档、Quartz、字典配置、日志通知文件、首页契约）
#   11-14 前端（Shared 包、Admin 脚手架、Mobile、Screen）
#   15-17 Admin 功能页面（用户角色租户 / 任务字典配置 / 日志文件公告）
#   18-19 集成测试 + 阶段性 Gate
#   20    菜单管理 + 动态路由
#   21    部门管理 + 数据权限
#   22    个人中心 + 登录日志 + 在线用户（后端）
#   23    Admin 前端页面 Batch 2
#   24    租户套餐 + 通知已读 + 导入导出
#   25    系统监控 + API 限流 + WebSocket
#   26    集成测试（Phase 20-25）
#   27    阶段性 Gate + 全量 Manifest v2
#   28    安全加固（XSS / 幂等 / Token 黑名单 / 登录锁定）
#   29    可观测性（TraceId / 结构化日志 / 慢 API / 前端错误监控）
#   30    数据变更审计 + 日志清理
#   31    前端增强（v-permission / 数据变更日志页面）
#   32    Final Gate v3
#   33    多级缓存管理器
#   34    Outbox 事件表
#   35    结构化日志与 Loki 集成
#   36    Prometheus 指标监控
#   37    Grafana 仪表盘与告警
#   38    租户品牌配置
#   39    数据脱敏
#   40    岗位管理
#   41    租户生命周期管理
#   42    超级管理员机制
#   43    租户域名识别
#   44    角色自定义数据范围
#   45    任务执行日志
#   46    导入导出中心
#   47    开放 API — 应用管理
#   48    开放 API — 密钥管理
#   49    Webhook 事件推送
#   50    消息中台 — 模板管理
#   51    消息中台 — 消息记录
#   52    消息中台 — 订阅管理
#   53    流程引擎（简化版）
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

# ── Argument parsing ───────────────────────────────────────
FROM_PHASE=0
ONLY_PHASE=""
DRY_RUN=false
TOTAL_PHASES=54   # Phase 0–53

# CI Gate 参数
CHECKPOINTS=""          # 逗号分隔的 checkpoint phase 号，如 "5,10,18,27,32"
GITHUB_REPO=""          # owner/repo
GITHUB_WORKFLOW="build-and-notify.yml"
AUTO_COMMIT=false       # 是否自动 git add -A && git commit

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)       FROM_PHASE="$2";       shift 2 ;;
    --only)       ONLY_PHASE="$2";       shift 2 ;;
    --dry-run)    DRY_RUN=true;          shift ;;
    --checkpoint) CHECKPOINTS="$2";      shift 2 ;;
    --repo)       GITHUB_REPO="$2";      shift 2 ;;
    --workflow)   GITHUB_WORKFLOW="$2";  shift 2 ;;
    --auto-commit) AUTO_COMMIT=true;     shift ;;
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

# CI Gate: 判断某 phase 是否为 checkpoint
is_checkpoint() {
  local p="$1"
  [[ -z "$CHECKPOINTS" ]] && return 1
  local IFS=','
  for x in $CHECKPOINTS; do
    [[ "$x" == "$p" ]] && return 0
  done
  return 1
}

# CI Gate: 是否有未提交的变更
git_has_changes() {
  [[ -n "$(git status --porcelain)" ]]
}

# CI Gate: 自动提交（可选）并 push
git_commit_push() {
  local phase="$1"
  local padded
  padded=$(printf '%02d' "$phase")

  if $AUTO_COMMIT && git_has_changes; then
    git add -A
    git commit -m "chore(phase-${padded}): checkpoint commit [ci gate]" || true
  fi

  git push
}

# CI Gate: 等待 GitHub Actions workflow 完成
wait_ci_green() {
  local sha="$1"
  bash scripts/wait-github-workflow.sh \
    --repo "$GITHUB_REPO" \
    --sha "$sha" \
    --workflow "$GITHUB_WORKFLOW" \
    --timeout-sec 7200 \
    --interval-sec 15
}

# CI Gate: 执行完整的 checkpoint 流程（push → 等绿 → 失败则中止）
run_checkpoint() {
  local phase="$1"

  if [[ -z "$GITHUB_REPO" ]]; then
    echo "[CI Gate] --checkpoint 已配置，但缺少 --repo 参数，中止。"
    exit 2
  fi

  echo ""
  echo "──────────────────────────────────────────────────"
  echo "[CI Gate] Checkpoint 触发：Phase $phase"
  echo "[CI Gate] Committing & pushing..."
  git_commit_push "$phase"

  local sha
  sha="$(git rev-parse HEAD)"
  echo "[CI Gate] HEAD sha=${sha:0:12}"
  echo "[CI Gate] Waiting for workflow '${GITHUB_WORKFLOW}'..."

  if wait_ci_green "$sha"; then
    echo "[CI Gate] PASSED — 继续执行后续 Phase"
    echo "──────────────────────────────────────────────────"
    echo ""
  else
    echo "[CI Gate] FAILED — 停在 Phase $phase 的 checkpoint"
    echo "  修复后可用 --from $((phase + 1)) 续跑"
    echo "──────────────────────────────────────────────────"
    exit 10
  fi
}

is_completed() {
  local phase="$1"
  [[ -f "$MANIFEST" ]] || return 1
  awk -v p="## PHASE $phase" '
    $0 == p { found=1; next }
    found && /^## PHASE / { exit }
    found && /(Status|Gate): PASSED/ { print; exit }
  ' "$MANIFEST" | grep -qE "(Status|Gate): PASSED"
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
[[ -n "$CHECKPOINTS" ]] && echo "  Checkpoints: ${CHECKPOINTS} (push + wait CI green)"
for phase in "${PHASE_LIST[@]}"; do
  padded=$(printf '%02d' "$phase")
  brief="spec/phase/phase-${padded}.md"
  title=$(grep -m1 '^title:' "$brief" 2>/dev/null | sed 's/title:[[:space:]]*//' | tr -d '"' || echo "?")
  cp_tag=""
  is_checkpoint "$phase" && cp_tag="  [CI GATE]"
  if is_completed "$phase"; then
    echo "  Phase $phase — $title  [ALREADY DONE — will skip]${cp_tag}"
  else
    echo "  Phase $phase — $title${cp_tag}"
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

    # CI Gate: checkpoint 检查（仅在非 --only 模式下触发）
    if [[ -z "$ONLY_PHASE" ]] && is_checkpoint "$phase"; then
      run_checkpoint "$phase"
    fi
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
