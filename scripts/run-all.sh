#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# run-all.sh — 全量编排器（Closed-Loop CI）
#
# 闭环阶段:
#   1) Collect  收集失败信号（本地 check JSON + GitHub check logs）
#   2) Diagnose 失败归因分类（A/B/C/D）
#   3) Repair   执行 repair recipes -> 复检 -> 最多 N 次迭代
#
# 用法:
#   bash scripts/run-all.sh
#   bash scripts/run-all.sh --from 5
#   bash scripts/run-all.sh --only 3
#   bash scripts/run-all.sh --dry-run
#
# CI Gate:
#   bash scripts/run-all.sh \
#     --checkpoint "5,10,18,27,32,44,53" \
#     --repo your-org/your-repo \
#     --workflow build-and-notify.yml \
#     --auto-commit
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

# ── Argument parsing ───────────────────────────────────────
FROM_PHASE=0
ONLY_PHASE=""
DRY_RUN=false
TOTAL_PHASES=54 # Phase 0–53

# CI Gate 参数
CHECKPOINTS=""
GITHUB_REPO=""
GITHUB_WORKFLOW="build-and-notify.yml"
AUTO_COMMIT=false

# Closed-loop 参数
MAX_REPAIR_ATTEMPTS=3
REPAIR_RECIPES="scripts/ci/repair-recipes.yaml"
POLICY_FILE="scripts/ci/closed-loop-policy.json"
ENABLE_AUTO_REPAIR=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)            FROM_PHASE="$2"; shift 2 ;;
    --only)            ONLY_PHASE="$2"; shift 2 ;;
    --dry-run)         DRY_RUN=true; shift ;;
    --checkpoint)      CHECKPOINTS="$2"; shift 2 ;;
    --repo)            GITHUB_REPO="$2"; shift 2 ;;
    --workflow)        GITHUB_WORKFLOW="$2"; shift 2 ;;
    --auto-commit)     AUTO_COMMIT=true; shift ;;
    --repair-attempts) MAX_REPAIR_ATTEMPTS="$2"; shift 2 ;;
    --repair-recipes)  REPAIR_RECIPES="$2"; shift 2 ;;
    --policy-file)     POLICY_FILE="$2"; shift 2 ;;
    --no-auto-repair)  ENABLE_AUTO_REPAIR=false; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if ! [[ "$MAX_REPAIR_ATTEMPTS" =~ ^[0-9]+$ ]]; then
  echo "--repair-attempts must be a non-negative integer"
  exit 2
fi

# ── Setup ──────────────────────────────────────────────────
mkdir -p logs artifacts/closed-loop
MANIFEST="PHASE_MANIFEST.txt"
FAILED_LOG="logs/failed.log"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_ARTIFACT_DIR="artifacts/closed-loop/${RUN_ID}"
mkdir -p "$RUN_ARTIFACT_DIR"

: > "$FAILED_LOG"

# ── Helpers ────────────────────────────────────────────────
is_checkpoint() {
  local p="$1"
  [[ -z "$CHECKPOINTS" ]] && return 1
  local IFS=','
  for x in $CHECKPOINTS; do
    [[ "$x" == "$p" ]] && return 0
  done
  return 1
}

git_has_changes() {
  [[ -n "$(git status --porcelain)" ]]
}

git_commit_push() {
  local phase="$1"
  local message="$2"
  local padded
  padded="$(printf '%02d' "$phase")"

  if git_has_changes; then
    if $AUTO_COMMIT; then
      git add -A
      git commit -m "${message} [phase-${padded}]" || true
    else
      echo "[CI Gate] 工作区有未提交改动，但未开启 --auto-commit。"
      echo "         无法自动 push 修复补丁。"
      return 20
    fi
  fi

  git push
}

wait_ci_green() {
  local sha="$1"
  bash scripts/wait-github-workflow.sh \
    --repo "$GITHUB_REPO" \
    --sha "$sha" \
    --workflow "$GITHUB_WORKFLOW" \
    --timeout-sec 7200 \
    --interval-sec 15
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

run_structured_check() {
  local check_name="$1"
  local phase="$2"
  local attempt="$3"
  local source="$4"
  local artifact_dir="$5"
  shift 5

  local safe_name="${check_name//\//-}"
  safe_name="${safe_name// /-}"
  local log_path="${artifact_dir}/logs/${safe_name}.log"
  local json_path="${artifact_dir}/checks/${safe_name}.json"
  mkdir -p "$(dirname "$log_path")" "$(dirname "$json_path")"

  set +e
  "$@" 2>&1 | tee "$log_path"
  local rc=${PIPESTATUS[0]}
  set -e

  local status="pass"
  [[ "$rc" -ne 0 ]] && status="fail"

  local summary
  summary="$(grep -Eim1 'error|fail|exception|timeout|fatal' "$log_path" || true)"
  if [[ -z "$summary" ]]; then
    if [[ "$status" == "pass" ]]; then
      summary="check passed"
    else
      summary="check failed (exit ${rc})"
    fi
  fi

  local errors_json
  errors_json="$(
    { grep -Ein 'error|fail|exception|timeout|fatal|traceback' "$log_path" 2>/dev/null || true; } \
      | head -n 50 \
      | cut -d: -f2- \
      | jq -R -s 'split("\n") | map(select(length>0))'
  )"

  jq -n \
    --arg check "$check_name" \
    --arg status "$status" \
    --argjson exitCode "$rc" \
    --arg summary "$summary" \
    --arg logPath "$log_path" \
    --arg source "$source" \
    --arg phase "$phase" \
    --argjson attempt "$attempt" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson errors "$errors_json" \
    '{
      check: $check,
      status: $status,
      exitCode: $exitCode,
      summary: $summary,
      logPath: $logPath,
      source: $source,
      phase: $phase,
      attempt: $attempt,
      timestamp: $timestamp,
      errors: $errors
    }' >"$json_path"

  return "$rc"
}

collect_diagnose_repair() {
  local phase="$1"
  local attempt="$2"
  local artifact_dir="$3"
  local github_file="${4:-}"

  local collect_json="${artifact_dir}/collect.json"
  local diagnosis_json="${artifact_dir}/diagnosis.json"
  local repair_json="${artifact_dir}/repair.json"
  local checks_dir="${artifact_dir}/checks"

  local collect_cmd=(
    bash scripts/ci/closed-loop-collect.sh
    --phase "$phase"
    --attempt "$attempt"
    --checks-dir "$checks_dir"
    --output "$collect_json"
  )
  if [[ -n "$github_file" && -f "$github_file" ]]; then
    collect_cmd+=(--github-file "$github_file")
  fi
  "${collect_cmd[@]}"

  bash scripts/ci/closed-loop-diagnose.sh \
    --collect "$collect_json" \
    --output "$diagnosis_json"

  CLOSED_LOOP_PHASE="$phase" \
    CLOSED_LOOP_ATTEMPT="$attempt" \
    CLOSED_LOOP_POLICY_FILE="$POLICY_FILE" \
    bash scripts/ci/closed-loop-repair.sh \
      --diagnosis "$diagnosis_json" \
      --recipes "$REPAIR_RECIPES" \
      --output "$repair_json"
}

execute_phase_with_closed_loop() {
  local phase="$1"
  local executor="$2"
  local padded
  padded="$(printf '%02d' "$phase")"
  local phase_artifact_dir="${RUN_ARTIFACT_DIR}/phase-${padded}"
  local attempt=1

  while (( attempt <= MAX_REPAIR_ATTEMPTS + 1 )); do
    local attempt_dir="${phase_artifact_dir}/local-attempt-${attempt}"
    mkdir -p "$attempt_dir"
    echo "[ClosedLoop][Local] Phase $phase attempt $attempt/$((MAX_REPAIR_ATTEMPTS + 1))"

    if run_structured_check \
      "phase-${padded}-execute" \
      "$padded" \
      "$attempt" \
      "local" \
      "$attempt_dir" \
      bash "$executor" "$phase" "--skip-preflight"; then
      cp -f "${attempt_dir}/logs/phase-${padded}-execute.log" "logs/phase-${padded}/run.log" 2>/dev/null || true
      return 0
    fi

    cp -f "${attempt_dir}/logs/phase-${padded}-execute.log" "logs/phase-${padded}/run.log" 2>/dev/null || true

    if ! $ENABLE_AUTO_REPAIR || (( attempt > MAX_REPAIR_ATTEMPTS )); then
      echo "[ClosedLoop][Local] 自动修复未启用或已达到最大尝试次数。"
      return 1
    fi

    echo "[ClosedLoop][Local] Collect -> Diagnose -> Repair"
    local repair_rc=0
    if ! collect_diagnose_repair "$padded" "$attempt" "$attempt_dir"; then
      repair_rc=$?
    fi

    local applied=0
    if [[ -f "${attempt_dir}/repair.json" ]]; then
      applied="$(jq -r '.summary.applied // 0' "${attempt_dir}/repair.json" 2>/dev/null || echo 0)"
    fi

    if [[ "$repair_rc" -eq 11 || "$applied" -eq 0 ]]; then
      echo "[ClosedLoop][Local] 没有匹配的 repair recipe，停止自动修复。"
      return 1
    fi
    if [[ "$repair_rc" -ne 0 && "$repair_rc" -ne 11 ]]; then
      echo "[ClosedLoop][Local] repair recipe 执行失败（rc=${repair_rc}）。"
    fi

    # 修复后先做一次相关 gate 复检，保留证据链。
    run_structured_check \
      "phase-${padded}-gate-verify" \
      "$padded" \
      "$attempt" \
      "local" \
      "$attempt_dir" \
      bash scripts/gates/gate-all.sh "$phase" || true

    attempt=$((attempt + 1))
  done

  return 1
}

run_checkpoint_with_closed_loop() {
  local phase="$1"
  local padded
  padded="$(printf '%02d' "$phase")"

  if [[ -z "$GITHUB_REPO" ]]; then
    echo "[CI Gate] --checkpoint 已配置，但缺少 --repo 参数。"
    return 2
  fi

  local ci_attempt=1
  while (( ci_attempt <= MAX_REPAIR_ATTEMPTS + 1 )); do
    local ci_dir="${RUN_ARTIFACT_DIR}/phase-${padded}/ci-attempt-${ci_attempt}"
    mkdir -p "$ci_dir"

    echo ""
    echo "──────────────────────────────────────────────────"
    echo "[CI Gate] Checkpoint：Phase $phase attempt $ci_attempt/$((MAX_REPAIR_ATTEMPTS + 1))"
    echo "[CI Gate] Committing & pushing..."
    if ! git_commit_push "$phase" "chore(ci-gate): checkpoint auto-commit"; then
      return 20
    fi

    local sha
    sha="$(git rev-parse HEAD)"
    echo "[CI Gate] HEAD sha=${sha:0:12}"
    echo "[CI Gate] Waiting for workflow '${GITHUB_WORKFLOW}'..."

    if run_structured_check \
      "phase-${padded}-github-workflow" \
      "$padded" \
      "$ci_attempt" \
      "github" \
      "$ci_dir" \
      bash scripts/wait-github-workflow.sh \
        --repo "$GITHUB_REPO" \
        --sha "$sha" \
        --workflow "$GITHUB_WORKFLOW" \
        --timeout-sec 7200 \
        --interval-sec 15; then
      echo "[CI Gate] PASSED — 继续执行后续 Phase"
      echo "──────────────────────────────────────────────────"
      echo ""
      return 0
    fi

    if ! $ENABLE_AUTO_REPAIR || (( ci_attempt > MAX_REPAIR_ATTEMPTS )); then
      echo "[CI Gate] FAILED — 已达到最大尝试次数。"
      echo "──────────────────────────────────────────────────"
      return 10
    fi

    echo "[CI Gate] FAILED — 进入 Collect -> Diagnose -> Repair"
    bash scripts/ci/collect-github-failures.sh \
      --repo "$GITHUB_REPO" \
      --workflow "$GITHUB_WORKFLOW" \
      --sha "$sha" \
      --output-dir "${ci_dir}/github" >/dev/null || true

    local github_file="${ci_dir}/github/github-checks.json"
    local repair_rc=0
    if ! collect_diagnose_repair "$padded" "$ci_attempt" "$ci_dir" "$github_file"; then
      repair_rc=$?
    fi

    local applied=0
    if [[ -f "${ci_dir}/repair.json" ]]; then
      applied="$(jq -r '.summary.applied // 0' "${ci_dir}/repair.json" 2>/dev/null || echo 0)"
    fi

    if [[ "$repair_rc" -eq 11 || "$applied" -eq 0 ]]; then
      echo "[CI Gate] 无匹配修复配方，停止自动修复。"
      return 10
    fi
    if [[ "$repair_rc" -ne 0 && "$repair_rc" -ne 11 ]]; then
      echo "[CI Gate] repair recipe 执行失败（rc=${repair_rc}）。"
    fi

    run_structured_check \
      "phase-${padded}-post-repair-gate" \
      "$padded" \
      "$ci_attempt" \
      "local" \
      "$ci_dir" \
      bash scripts/gates/gate-all.sh "$phase" || true

    ci_attempt=$((ci_attempt + 1))
  done

  return 10
}

# ── Pre-flight ─────────────────────────────────────────────
echo "════════════════════════════════════════════════════"
echo "  LJWX Platform — Full Generation Run (Closed-Loop)"
echo "  Start: $(date)"
echo "  Phases: $FROM_PHASE – $((TOTAL_PHASES - 1))"
echo "  Auto Repair: $ENABLE_AUTO_REPAIR | Max Attempts: $MAX_REPAIR_ATTEMPTS"
echo "  Repair Recipes: $REPAIR_RECIPES"
echo "  Policy File: $POLICY_FILE"
echo "  Artifacts: $RUN_ARTIFACT_DIR"
[[ -n "$ONLY_PHASE" ]] && echo "  Mode: only Phase $ONLY_PHASE"
$DRY_RUN && echo "  Mode: DRY RUN"
echo "════════════════════════════════════════════════════"
echo ""

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required by closed-loop collector/diagnoser/repairer."
  exit 2
fi

if [[ ! -f "$REPAIR_RECIPES" ]]; then
  echo "Repair recipes not found: $REPAIR_RECIPES"
  exit 2
fi

if [[ ! -f "$POLICY_FILE" ]]; then
  echo "Closed-loop policy file not found: $POLICY_FILE"
  exit 2
fi

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
  padded="$(printf '%02d' "$phase")"
  brief="spec/phase/phase-${padded}.md"
  title="$(grep -m1 '^title:' "$brief" 2>/dev/null | sed 's/title:[[:space:]]*//' | tr -d '"' || echo "?")"
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
  padded="$(printf '%02d' "$phase")"

  echo ""
  echo ">>>>>>>>>> Phase $phase <<<<<<<<<<"

  if is_completed "$phase"; then
    echo "  Phase $phase already completed — skipping."
    SKIPPED=$((SKIPPED + 1))
    PASSED=$((PASSED + 1))
    continue
  fi

  PHASE_BRIEF="spec/phase/phase-${padded}.md"
  YAML_BLOCK="$(awk '/^---$/{n++;if(n==1){next};if(n==2){exit}} n==1{print}' "$PHASE_BRIEF")"
  T_BE="$(echo "$YAML_BLOCK" | grep 'backend:' | awk '{print $2}' | head -1 || true)"
  T_FE="$(echo "$YAML_BLOCK" | grep 'frontend:' | awk '{print $2}' | head -1 || true)"

  EXECUTOR="scripts/phase-execute.sh"
  if [[ "${T_BE:-false}" == "true" && "${T_FE:-false}" == "true" ]]; then
    EXECUTOR="scripts/phase-parallel.sh"
  fi

  mkdir -p "logs/phase-${padded}"

  if execute_phase_with_closed_loop "$phase" "$EXECUTOR"; then
    echo "Phase $phase — PASSED"
    PASSED=$((PASSED + 1))

    if [[ -z "$ONLY_PHASE" ]] && is_checkpoint "$phase"; then
      if ! run_checkpoint_with_closed_loop "$phase"; then
        echo "[CI Gate] FAILED — 停在 Phase $phase 的 checkpoint"
        echo "Phase $phase CHECKPOINT FAILED — $(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$FAILED_LOG"
        FAILED=$((FAILED + 1))
        exit 10
      fi
    fi
  else
    echo "Phase $phase — FAILED"
    echo "Phase $phase FAILED — $(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$FAILED_LOG"
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
echo "  Closed-loop artifacts: $RUN_ARTIFACT_DIR"
echo "════════════════════════════════════════════════════"

exit "$FAILED"
