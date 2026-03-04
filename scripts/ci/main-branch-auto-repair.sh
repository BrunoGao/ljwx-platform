#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

REPO=""
RUN_ID=""
WORKFLOW_NAME=""
BRANCH=""
MAX_ATTEMPTS=3
RECIPES="scripts/ci/repair-recipes.yaml"
POLICY_FILE="scripts/ci/closed-loop-policy.json"
GITHUB_OUTPUT_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/ci/main-branch-auto-repair.sh \
    --repo owner/repo \
    --run-id 123456 \
    --workflow-name "Gate Check" \
    --branch master \
    [--max-attempts 3] \
    [--recipes scripts/ci/repair-recipes.yaml] \
    [--policy-file scripts/ci/closed-loop-policy.json] \
    [--github-output <path>]
USAGE
}

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "$GITHUB_OUTPUT_FILE" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT_FILE"
  fi
}

parse_attempt_from_subject() {
  local subject="$1"
  local parsed
  parsed="$(printf '%s\n' "$subject" | sed -nE 's/.*\[auto-repair attempt ([0-9]+)\/[0-9]+\].*/\1/p' | head -n 1)"
  if [[ "$parsed" =~ ^[0-9]+$ ]]; then
    echo "$parsed"
  else
    echo "0"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --run-id) RUN_ID="$2"; shift 2 ;;
    --workflow-name) WORKFLOW_NAME="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --max-attempts) MAX_ATTEMPTS="$2"; shift 2 ;;
    --recipes) RECIPES="$2"; shift 2 ;;
    --policy-file) POLICY_FILE="$2"; shift 2 ;;
    --github-output) GITHUB_OUTPUT_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "[auto-repair] 未知参数: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$REPO" || -z "$RUN_ID" ]]; then
  echo "[auto-repair] 缺少必填参数 --repo / --run-id" >&2
  usage
  exit 2
fi

if ! [[ "$RUN_ID" =~ ^[0-9]+$ ]]; then
  echo "[auto-repair] run-id 必须是数字: ${RUN_ID}" >&2
  exit 2
fi

if ! [[ "$MAX_ATTEMPTS" =~ ^[0-9]+$ ]] || [[ "$MAX_ATTEMPTS" -lt 1 ]]; then
  echo "[auto-repair] --max-attempts 必须是 >=1 的整数" >&2
  exit 2
fi

if [[ ! -f "$RECIPES" ]]; then
  echo "[auto-repair] 修复配方不存在: $RECIPES" >&2
  exit 2
fi

if [[ ! -f "$POLICY_FILE" ]]; then
  echo "[auto-repair] 策略文件不存在: $POLICY_FILE" >&2
  exit 2
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH="$(gh api -H 'Accept: application/vnd.github+json' "/repos/${REPO}/actions/runs/${RUN_ID}" --jq '.head_branch' 2>/dev/null || true)"
fi

if [[ -z "$WORKFLOW_NAME" ]]; then
  WORKFLOW_NAME="$(gh api -H 'Accept: application/vnd.github+json' "/repos/${REPO}/actions/runs/${RUN_ID}" --jq '.name' 2>/dev/null || true)"
fi

if [[ -z "$BRANCH" ]]; then
  echo "[auto-repair] 无法解析失败 run 对应分支" >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "[auto-repair] 缺少 gh CLI" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[auto-repair] 缺少 jq" >&2
  exit 2
fi

git fetch origin "$BRANCH" --quiet
git checkout -B "$BRANCH" "origin/$BRANCH"

last_subject="$(git log -1 --pretty=%s || true)"
current_attempt="$(parse_attempt_from_subject "$last_subject")"
next_attempt=$((current_attempt + 1))

emit_output "branch" "$BRANCH"
emit_output "source_run_id" "$RUN_ID"
emit_output "source_workflow" "$WORKFLOW_NAME"
emit_output "attempt" "$next_attempt"
emit_output "max_attempts" "$MAX_ATTEMPTS"

if (( next_attempt > MAX_ATTEMPTS )); then
  echo "[auto-repair] 已达到最大自动修复次数: ${current_attempt}/${MAX_ATTEMPTS}" >&2
  emit_output "status" "max_attempt"
  exit 21
fi

ARTIFACT_DIR="artifacts/closed-loop/main-branch/run-${RUN_ID}/attempt-${next_attempt}"
mkdir -p "$ARTIFACT_DIR/checks" "$ARTIFACT_DIR/github"

echo "[auto-repair] 收集失败流水线信号: run=${RUN_ID} workflow=${WORKFLOW_NAME} branch=${BRANCH}"
bash scripts/ci/collect-github-failures.sh \
  --repo "$REPO" \
  --run-id "$RUN_ID" \
  --output-dir "$ARTIFACT_DIR/github" >/dev/null || true

GITHUB_CHECK_FILE="$ARTIFACT_DIR/github/github-checks.json"
COLLECT_FILE="$ARTIFACT_DIR/collect.json"
DIAGNOSIS_FILE="$ARTIFACT_DIR/diagnosis.json"
REPAIR_FILE="$ARTIFACT_DIR/repair.json"

bash scripts/ci/closed-loop-collect.sh \
  --phase main \
  --attempt "$next_attempt" \
  --checks-dir "$ARTIFACT_DIR/checks" \
  --github-file "$GITHUB_CHECK_FILE" \
  --output "$COLLECT_FILE" >/dev/null

bash scripts/ci/closed-loop-diagnose.sh \
  --collect "$COLLECT_FILE" \
  --output "$DIAGNOSIS_FILE" >/dev/null

set +e
CLOSED_LOOP_PHASE="main" \
CLOSED_LOOP_ATTEMPT="$next_attempt" \
CLOSED_LOOP_POLICY_FILE="$POLICY_FILE" \
  bash scripts/ci/closed-loop-repair.sh \
    --diagnosis "$DIAGNOSIS_FILE" \
    --recipes "$RECIPES" \
    --output "$REPAIR_FILE"
repair_rc=$?
set -e

applied="$(jq -r '.summary.applied // 0' "$REPAIR_FILE" 2>/dev/null || echo 0)"
passed="$(jq -r '.summary.passed // 0' "$REPAIR_FILE" 2>/dev/null || echo 0)"

emit_output "repair_rc" "$repair_rc"
emit_output "repair_applied" "$applied"
emit_output "repair_passed" "$passed"
emit_output "repair_json" "$REPAIR_FILE"

if [[ "$repair_rc" -eq 11 || "$applied" -eq 0 ]]; then
  echo "[auto-repair] 未匹配到可执行修复配方，转人工" >&2
  emit_output "status" "no_fix"
  exit 11
fi

if [[ "$repair_rc" -ne 0 && "$repair_rc" -ne 11 ]]; then
  echo "[auto-repair] 修复执行失败 (rc=${repair_rc})" >&2
  emit_output "status" "repair_failed"
  exit 22
fi

if git diff --quiet; then
  echo "[auto-repair] 修复脚本未产生代码变更，转人工" >&2
  emit_output "status" "no_diff"
  exit 11
fi

failed_checks="$(jq -r '.failed[]?.check // empty' "$COLLECT_FILE" | head -n 3 | paste -sd ',' -)"
if [[ -z "$failed_checks" ]]; then
  failed_checks="workflow-failure"
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A

subject="fix(ci): auto repair for ${WORKFLOW_NAME:-workflow} [auto-repair attempt ${next_attempt}/${MAX_ATTEMPTS}]"
body_1="source-run-id: ${RUN_ID}"
body_2="source-workflow: ${WORKFLOW_NAME:-unknown}"
body_3="failed-checks: ${failed_checks}"

if git diff --cached --quiet; then
  echo "[auto-repair] 没有暂存变更，转人工" >&2
  emit_output "status" "no_staged_changes"
  exit 11
fi

git commit -m "$subject" -m "$body_1" -m "$body_2" -m "$body_3"
git push origin "HEAD:${BRANCH}"

echo "[auto-repair] 已提交并推送自动修复补丁到 ${BRANCH}"
emit_output "status" "fixed"
emit_output "commit_subject" "$subject"
exit 0
