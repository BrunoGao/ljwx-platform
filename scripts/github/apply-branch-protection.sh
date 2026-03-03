#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=true
REPO="${GITHUB_REPOSITORY:-}"
APPROVALS=1
CHECKS=(
  "Lint"
  "Backend"
  "Frontend"
  "gate"
  "pr-policy"
  "dependency-review"
  "Gitleaks"
  "Backend JaCoCo"
)
BRANCHES=()

usage() {
  cat <<USAGE
用法: scripts/github/apply-branch-protection.sh [options]

选项:
  --dry-run                 仅打印将执行的命令（默认）
  --apply                   实际执行变更
  --repo <owner/repo>       指定仓库，默认自动检测
  --branch <name>           目标分支，可重复（默认: main + master）
  --approvals <n>           需要审批数，默认 1
  --checks <a,b,c>          必须通过的状态检查列表（逗号分隔）
  -h, --help                显示帮助
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[错误] 缺少命令: $cmd" >&2
    exit 1
  fi
}

detect_repo() {
  local origin
  origin="$(git config --get remote.origin.url 2>/dev/null || true)"

  case "$origin" in
    git@github.com:*.git)
      REPO="${origin#git@github.com:}"
      REPO="${REPO%.git}"
      ;;
    https://github.com/*/*.git)
      REPO="${origin#https://github.com/}"
      REPO="${REPO%.git}"
      ;;
    https://github.com/*/*)
      REPO="${origin#https://github.com/}"
      ;;
  esac
}

join_checks() {
  local input="$1"
  IFS=',' read -r -a CHECKS <<< "$input"
  for i in "${!CHECKS[@]}"; do
    CHECKS[$i]="$(echo "${CHECKS[$i]}" | xargs)"
  done
}

print_cmd() {
  printf '[dry-run] '
  printf '%q ' "$@"
  echo
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --apply)
      DRY_RUN=false
      shift
      ;;
    --repo)
      REPO="${2:?missing value for --repo}"
      shift 2
      ;;
    --branch)
      BRANCHES+=("${2:?missing value for --branch}")
      shift 2
      ;;
    --approvals)
      APPROVALS="${2:?missing value for --approvals}"
      shift 2
      ;;
    --checks)
      join_checks "${2:?missing value for --checks}"
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
  detect_repo
fi
if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi
if [[ -z "$REPO" ]]; then
  echo "[错误] 无法检测仓库，请通过 --repo 指定 owner/repo" >&2
  exit 1
fi

if [[ "${#BRANCHES[@]}" -eq 0 ]]; then
  BRANCHES=(main master)
fi

if ! [[ "$APPROVALS" =~ ^[0-9]+$ ]]; then
  echo "[错误] --approvals 必须是整数" >&2
  exit 1
fi

if (( APPROVALS < 1 || APPROVALS > 6 )); then
  echo "[错误] --approvals 必须在 1..6 范围内" >&2
  exit 1
fi

contexts_json="$(printf '%s\n' "${CHECKS[@]}" | jq -R . | jq -s .)"
payload="$(jq -n \
  --argjson contexts "$contexts_json" \
  --argjson approvals "$APPROVALS" \
  '{
    required_status_checks: {
      strict: true,
      contexts: $contexts
    },
    enforce_admins: true,
    required_pull_request_reviews: {
      dismiss_stale_reviews: true,
      require_code_owner_reviews: true,
      required_approving_review_count: $approvals,
      require_last_push_approval: true
    },
    restrictions: null,
    required_linear_history: true,
    allow_force_pushes: false,
    allow_deletions: false,
    block_creations: false,
    required_conversation_resolution: true,
    lock_branch: false,
    allow_fork_syncing: true
  }')"

tmp_payload="$(mktemp)"
printf '%s\n' "$payload" > "$tmp_payload"

echo "[信息] 仓库: $REPO"
echo "[信息] 分支: ${BRANCHES[*]}"
echo "[信息] 必需检查: ${CHECKS[*]}"

for branch in "${BRANCHES[@]}"; do
  if ! gh api "repos/$REPO/branches/$branch" >/dev/null 2>&1; then
    echo "[跳过] 分支不存在: $branch"
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[预览] 将为分支 $branch 应用保护规则:"
    cat "$tmp_payload"
    print_cmd gh api --method PUT "repos/$REPO/branches/$branch/protection" --input "$tmp_payload"
    continue
  fi

  gh api --method PUT "repos/$REPO/branches/$branch/protection" --input "$tmp_payload" >/dev/null
  echo "[完成] 分支保护已应用: $branch"
done

rm -f "$tmp_payload"

echo "[完成] 脚本执行结束"
