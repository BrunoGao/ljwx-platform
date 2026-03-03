#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=true
REPO="${GITHUB_REPOSITORY:-}"
ENVIRONMENTS=()

usage() {
  cat <<USAGE
用法: scripts/github/setup-environments.sh [options]

选项:
  --dry-run                 仅打印将执行的命令（默认）
  --apply                   实际执行变更
  --repo <owner/repo>       指定仓库，默认自动检测
  --env <name>              需要确保存在的环境，可重复（默认: staging + production）
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
    --env)
      ENVIRONMENTS+=("${2:?missing value for --env}")
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

if [[ "${#ENVIRONMENTS[@]}" -eq 0 ]]; then
  ENVIRONMENTS=(staging production)
fi

echo "[信息] 仓库: $REPO"
echo "[信息] 环境: ${ENVIRONMENTS[*]}"

for env_name in "${ENVIRONMENTS[@]}"; do
  if [[ "$DRY_RUN" == "true" ]]; then
    print_cmd gh api --method PUT "repos/$REPO/environments/$env_name"
    continue
  fi

  gh api --method PUT "repos/$REPO/environments/$env_name" >/dev/null
  echo "[完成] 环境已确保存在: $env_name"
done

echo "[完成] 脚本执行结束"
