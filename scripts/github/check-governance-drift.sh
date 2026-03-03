#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
EXPECTED_BRANCHES_CSV="${EXPECTED_PROTECTED_BRANCHES:-main,master}"
EXPECTED_CHECKS_CSV="${EXPECTED_REQUIRED_CHECKS:-Lint,Backend,Frontend,gate,pr-policy,dependency-review,Gitleaks,Backend JaCoCo}"
EXPECTED_ENVS_CSV="${EXPECTED_ENVIRONMENTS:-staging,production}"

usage() {
  cat <<USAGE
用法: scripts/github/check-governance-drift.sh [options]

选项:
  --repo <owner/repo>      指定仓库，默认使用 GITHUB_REPOSITORY
  --branches <a,b,c>       期望受保护分支列表（逗号分隔）
  --checks <a,b,c>         期望必需状态检查列表（逗号分隔）
  --envs <a,b,c>           期望环境列表（逗号分隔）
  -h, --help               显示帮助
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[错误] 缺少命令: $cmd" >&2
    exit 1
  fi
}

trim_array_in_place() {
  local -n ref=$1
  local trimmed=()
  local value
  for value in "${ref[@]}"; do
    value="$(echo "$value" | xargs)"
    if [[ -n "$value" ]]; then
      trimmed+=("$value")
    fi
  done
  ref=("${trimmed[@]}")
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:?missing value for --repo}"
      shift 2
      ;;
    --branches)
      EXPECTED_BRANCHES_CSV="${2:?missing value for --branches}"
      shift 2
      ;;
    --checks)
      EXPECTED_CHECKS_CSV="${2:?missing value for --checks}"
      shift 2
      ;;
    --envs)
      EXPECTED_ENVS_CSV="${2:?missing value for --envs}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[错误] 未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd gh
require_cmd jq

if [[ -z "$REPO" ]]; then
  echo "[错误] 缺少仓库信息，请通过 --repo 指定 owner/repo" >&2
  exit 1
fi

IFS=',' read -r -a expected_branches <<< "$EXPECTED_BRANCHES_CSV"
IFS=',' read -r -a expected_checks <<< "$EXPECTED_CHECKS_CSV"
IFS=',' read -r -a expected_envs <<< "$EXPECTED_ENVS_CSV"
trim_array_in_place expected_branches
trim_array_in_place expected_checks
trim_array_in_place expected_envs

if [[ "${#expected_branches[@]}" -eq 0 ]]; then
  echo "[错误] 受保护分支列表为空" >&2
  exit 1
fi

if [[ "${#expected_checks[@]}" -eq 0 ]]; then
  echo "[错误] 必需状态检查列表为空" >&2
  exit 1
fi

if [[ "${#expected_envs[@]}" -eq 0 ]]; then
  echo "[错误] 环境列表为空" >&2
  exit 1
fi

echo "[信息] 开始治理漂移检查: repo=$REPO"
echo "[信息] 期望受保护分支: ${expected_branches[*]}"
echo "[信息] 期望状态检查: ${expected_checks[*]}"
echo "[信息] 期望环境: ${expected_envs[*]}"

violations=()

add_violation() {
  local msg="$1"
  violations+=("$msg")
  echo "[漂移] $msg"
}

for branch in "${expected_branches[@]}"; do
  if ! gh api "repos/$REPO/branches/$branch" >/dev/null 2>&1; then
    echo "[跳过] 分支不存在: $branch"
    continue
  fi

  protection_json="$(gh api "repos/$REPO/branches/$branch/protection" 2>/dev/null || true)"
  if [[ -z "$protection_json" ]]; then
    add_violation "分支 $branch 未启用保护规则，或当前 Token 无权限读取"
    continue
  fi

  if ! printf '%s' "$protection_json" | jq -e 'has("required_status_checks")' >/dev/null; then
    add_violation "分支 $branch 保护规则无法读取（疑似 Token 权限不足）"
    continue
  fi

  if [[ "$(printf '%s' "$protection_json" | jq -r '.required_status_checks.strict // false')" != "true" ]]; then
    add_violation "分支 $branch 未开启 strict required status checks"
  fi

  if [[ "$(printf '%s' "$protection_json" | jq -r '.enforce_admins.enabled // false')" != "true" ]]; then
    add_violation "分支 $branch 未开启管理员同样受保护"
  fi

  if [[ "$(printf '%s' "$protection_json" | jq -r '.required_pull_request_reviews.require_code_owner_reviews // false')" != "true" ]]; then
    add_violation "分支 $branch 未要求 CODEOWNERS 审核"
  fi

  review_count="$(printf '%s' "$protection_json" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')"
  if ! [[ "$review_count" =~ ^[0-9]+$ ]] || (( review_count < 1 )); then
    add_violation "分支 $branch 审批人数配置无效（当前: $review_count）"
  fi

  if [[ "$(printf '%s' "$protection_json" | jq -r '.required_conversation_resolution.enabled // false')" != "true" ]]; then
    add_violation "分支 $branch 未开启会话必须解决"
  fi

  if [[ "$(printf '%s' "$protection_json" | jq -r '.required_linear_history.enabled // false')" != "true" ]]; then
    add_violation "分支 $branch 未开启线性历史"
  fi

  if [[ "$(printf '%s' "$protection_json" | jq -r '.allow_force_pushes.enabled // false')" != "false" ]]; then
    add_violation "分支 $branch 允许 force push（应为禁用）"
  fi

  if [[ "$(printf '%s' "$protection_json" | jq -r '.allow_deletions.enabled // false')" != "false" ]]; then
    add_violation "分支 $branch 允许删除分支（应为禁用）"
  fi

  for check_name in "${expected_checks[@]}"; do
    if ! printf '%s' "$protection_json" | jq -e --arg ctx "$check_name" '.required_status_checks.contexts | index($ctx) != null' >/dev/null; then
      add_violation "分支 $branch 缺少必需状态检查: $check_name"
    fi
  done
done

for env_name in "${expected_envs[@]}"; do
  env_json="$(gh api "repos/$REPO/environments/$env_name" 2>/dev/null || true)"
  if [[ -z "$env_json" ]]; then
    add_violation "缺少环境: $env_name"
    continue
  fi

  if ! printf '%s' "$env_json" | jq -e '.name == "'"$env_name"'"' >/dev/null; then
    add_violation "环境 $env_name 无法读取（疑似 Token 权限不足）"
    continue
  fi

  echo "[通过] 环境存在: $env_name"

  if [[ "$env_name" == "production" ]]; then
    review_rule_count="$(printf '%s' "$env_json" | jq -r '[.protection_rules[]? | select(.type == "required_reviewers")] | length')"
    wait_timer_count="$(printf '%s' "$env_json" | jq -r '[.protection_rules[]? | select(.type == "wait_timer" and ((.wait_timer // 0) > 0))] | length')"

    if ! [[ "$review_rule_count" =~ ^[0-9]+$ ]]; then
      review_rule_count=0
    fi

    if ! [[ "$wait_timer_count" =~ ^[0-9]+$ ]]; then
      wait_timer_count=0
    fi

    if (( review_rule_count == 0 && wait_timer_count == 0 )); then
      add_violation "production 环境缺少保护规则（至少配置 required reviewers 或 wait timer）"
    fi
  fi
done

if [[ "${#violations[@]}" -gt 0 ]]; then
  echo ""
  echo "[结论] 发现治理漂移（${#violations[@]} 项）"
  printf '  - %s\n' "${violations[@]}"
  exit 1
fi

echo ""
echo "[结论] 未发现治理漂移"
