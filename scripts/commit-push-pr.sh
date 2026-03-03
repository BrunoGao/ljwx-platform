#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# commit-push-pr.sh — 自动化 commit、push 和创建 PR
# 用法: bash scripts/commit-push-pr.sh [options]
#
# 选项:
#   -m, --message <msg>     Commit 消息（必填）
#   -t, --title <title>     PR 标题（可选，默认使用 commit 消息）
#   -b, --body <body>       PR 描述（可选）
#   -B, --base <branch>     目标分支（可选，默认 master）
#   --draft                 创建草稿 PR
#   --no-pr                 只 commit 和 push，不创建 PR
#   --dry-run               预览操作，不实际执行
#
# 示例:
#   bash scripts/commit-push-pr.sh -m "fix: Phase 54-58 评审问题修复"
#   bash scripts/commit-push-pr.sh -m "feat: 新增功能" -t "新功能 PR" --draft
#   bash scripts/commit-push-pr.sh -m "chore: 更新文档" --no-pr
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# ── 默认值 ─────────────────────────────────────────────────
COMMIT_MESSAGE=""
PR_TITLE=""
PR_BODY=""
BASE_BRANCH="master"
CREATE_PR=true
DRAFT_PR=false
DRY_RUN=false

# ── 颜色输出 ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

# ── 参数解析 ───────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    -t|--title)
      PR_TITLE="$2"
      shift 2
      ;;
    -b|--body)
      PR_BODY="$2"
      shift 2
      ;;
    -B|--base)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --draft)
      DRAFT_PR=true
      shift
      ;;
    --no-pr)
      CREATE_PR=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# ── 参数验证 ───────────────────────────────────────────────
if [[ -z "$COMMIT_MESSAGE" ]]; then
  log_error "Commit message is required. Use -m or --message"
  exit 1
fi

# 如果没有指定 PR 标题，使用 commit 消息
if [[ -z "$PR_TITLE" ]]; then
  PR_TITLE="$COMMIT_MESSAGE"
fi

# ── 检查工作区状态 ─────────────────────────────────────────
if [[ -z "$(git status --porcelain)" ]]; then
  log_warn "No changes to commit"
  exit 0
fi

# ── 获取当前分支 ───────────────────────────────────────────
CURRENT_BRANCH=$(git branch --show-current)
if [[ -z "$CURRENT_BRANCH" ]]; then
  log_error "Not on any branch (detached HEAD)"
  exit 1
fi

log_info "Current branch: $CURRENT_BRANCH"
log_info "Base branch: $BASE_BRANCH"

# ── 显示将要提交的文件 ─────────────────────────────────────
echo ""
log_info "Files to be committed:"
git status --short
echo ""

# ── Dry run 模式 ───────────────────────────────────────────
if $DRY_RUN; then
  log_warn "DRY RUN MODE - No actual changes will be made"
  echo ""
  log_info "Would execute:"
  echo "  1. git add -A"
  echo "  2. git commit -m \"$COMMIT_MESSAGE\""
  echo "  3. git push origin $CURRENT_BRANCH"
  if $CREATE_PR; then
    echo "  4. gh pr create --base $BASE_BRANCH --head $CURRENT_BRANCH --title \"$PR_TITLE\""
    [[ -n "$PR_BODY" ]] && echo "     --body \"$PR_BODY\""
    $DRAFT_PR && echo "     --draft"
  fi
  exit 0
fi

# ── Step 1: Commit ─────────────────────────────────────────
log_info "Step 1: Committing changes..."
git add -A
git commit -m "$COMMIT_MESSAGE"
log_success "Committed successfully"

# ── Step 2: Push ───────────────────────────────────────────
log_info "Step 2: Pushing to origin/$CURRENT_BRANCH..."
git push origin "$CURRENT_BRANCH"
log_success "Pushed successfully"

# ── Step 3: Create PR (optional) ───────────────────────────
if ! $CREATE_PR; then
  log_info "Skipping PR creation (--no-pr flag)"
  exit 0
fi

# 检查 gh CLI 是否安装
if ! command -v gh >/dev/null 2>&1; then
  log_error "GitHub CLI (gh) is not installed"
  log_info "Install it from: https://cli.github.com/"
  log_info "Or skip PR creation with --no-pr flag"
  exit 1
fi

# 检查是否已经有 PR
EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")
if [[ -n "$EXISTING_PR" ]]; then
  log_warn "PR already exists for branch $CURRENT_BRANCH: #$EXISTING_PR"
  log_info "View PR: gh pr view $EXISTING_PR --web"
  exit 0
fi

log_info "Step 3: Creating pull request..."

# 构建 gh pr create 命令
PR_CMD=(gh pr create --base "$BASE_BRANCH" --head "$CURRENT_BRANCH" --title "$PR_TITLE")

if [[ -n "$PR_BODY" ]]; then
  PR_CMD+=(--body "$PR_BODY")
fi

if $DRAFT_PR; then
  PR_CMD+=(--draft)
fi

# 执行创建 PR
if "${PR_CMD[@]}"; then
  log_success "Pull request created successfully"

  # 获取 PR 编号
  PR_NUMBER=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")
  if [[ -n "$PR_NUMBER" ]]; then
    log_info "PR #$PR_NUMBER: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/pull/$PR_NUMBER"
  fi
else
  log_error "Failed to create pull request"
  exit 1
fi

echo ""
log_success "All done!"
