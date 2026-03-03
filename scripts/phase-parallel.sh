#!/usr/bin/env bash
set -euo pipefail

PHASE_NUM="${1:?Usage: phase-parallel.sh <phase-number>}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_BRIEF="spec/phase/phase-$(printf '%02d' "$PHASE_NUM").md"
source scripts/lib/parse-phase-brief.sh "$PHASE_BRIEF"

if [[ "$TARGET_BACKEND" != "true" || "$TARGET_FRONTEND" != "true" ]]; then
  echo "Phase $PHASE_NUM does not require both backend and frontend."
  echo "  Backend: $TARGET_BACKEND | Frontend: $TARGET_FRONTEND"
  echo "Use scripts/phase-execute.sh instead."
  exit 1
fi

MAIN_BRANCH=$(git branch --show-current)
# Record current HEAD before any merges — used for precise squash
PRE_MERGE_HEAD=$(git rev-parse HEAD)

BE_WT="phase${PHASE_NUM}-be"
FE_WT="phase${PHASE_NUM}-fe"
BE_BRANCH="worktree-${BE_WT}"
FE_BRANCH="worktree-${FE_WT}"
BE_DIR=".claude/worktrees/${BE_WT}"
FE_DIR=".claude/worktrees/${FE_WT}"
SHARED_STATE_PATHS=(
  "PHASE_MANIFEST.txt"
  "docs/reports/data/summary.json"
  "docs/reports/data/rtm.json"
  "docs/reports/data/tests.json"
  "docs/reports/data/phases"
  "docs/reports/data/history"
)

prune_shared_state_changes() {
  local worker="${1:-WT}"
  if ! git diff --quiet -- "${SHARED_STATE_PATHS[@]}" 2>/dev/null \
    || [[ -n "$(git ls-files --others --exclude-standard -- "${SHARED_STATE_PATHS[@]}")" ]]; then
    echo "[$worker] Dropping shared-state side effects (manifest/reports)."
  fi

  # Parallel branches must not carry manifest/report artifacts back to main.
  git restore --source=HEAD --staged --worktree -- "${SHARED_STATE_PATHS[@]}" >/dev/null 2>&1 || true
  git clean -fd -- "${SHARED_STATE_PATHS[@]}" >/dev/null 2>&1 || true
}

# ── Cleanup on exit ───────────────────────────────────────
cleanup() {
  echo ""
  echo "Cleaning up worktrees..."
  git worktree remove "$BE_DIR" --force 2>/dev/null || true
  git worktree remove "$FE_DIR" --force 2>/dev/null || true
  git branch -D "$BE_BRANCH" 2>/dev/null || true
  git branch -D "$FE_BRANCH" 2>/dev/null || true
}
trap cleanup EXIT

# ── Step 0: Preflight ─────────────────────────────────────
echo "═══ Preflight ═══"
bash scripts/preflight/preflight-check.sh
echo ""

# ── Step 1: Create isolated worktrees ─────────────────────
echo "═══ Creating worktrees ═══"
mkdir -p .claude/worktrees
git branch "$BE_BRANCH" HEAD
git branch "$FE_BRANCH" HEAD
git worktree add "$BE_DIR" "$BE_BRANCH"
git worktree add "$FE_DIR" "$FE_BRANCH"
echo "  Backend worktree: $BE_DIR ($BE_BRANCH)"
echo "  Frontend worktree: $FE_DIR ($FE_BRANCH)"
echo ""

# ── Step 2: Parallel generation ───────────────────────────
echo "═══ Parallel Generation — Phase $PHASE_NUM ═══"

(
  cd "$BE_DIR"
  echo "[BE] Starting backend generation..."
  claude -p "You are backend-builder. Execute Phase $PHASE_NUM backend tasks.
Read CLAUDE.md, spec/01-constraints.md, spec/08-output-rules.md, and $PHASE_BRIEF.
Generate ONLY backend files (.java, pom.xml, .xml, .yml, .sql, .properties).
Do NOT generate any frontend files (.vue, .ts, .json for node, .css, .html).
Do NOT run gate scripts, and do NOT modify PHASE_MANIFEST.txt or docs/reports/data/*.
Follow spec/08-output-rules.md for output format." \
    --agent backend-builder \
    --output-format text
  prune_shared_state_changes "BE"
  git add -A
  git commit -m "wip: phase-${PHASE_NUM} backend" --allow-empty
  echo "[BE] Done."
) &
PID_BE=$!

(
  cd "$FE_DIR"
  echo "[FE] Starting frontend generation..."
  claude -p "You are frontend-builder. Execute Phase $PHASE_NUM frontend tasks.
Read CLAUDE.md, spec/06-frontend-config.md, spec/08-output-rules.md, and $PHASE_BRIEF.
Generate ONLY frontend files (.vue, .ts, package.json, .scss, .html, tsconfig*.json).
Do NOT generate any backend files (.java, pom.xml, .sql, .yml backend configs).
Do NOT run gate scripts, and do NOT modify PHASE_MANIFEST.txt or docs/reports/data/*.
Follow spec/08-output-rules.md for output format." \
    --agent frontend-builder \
    --output-format text
  prune_shared_state_changes "FE"
  git add -A
  git commit -m "wip: phase-${PHASE_NUM} frontend" --allow-empty
  echo "[FE] Done."
) &
PID_FE=$!

echo "Backend PID: $PID_BE | Frontend PID: $PID_FE"
echo "Waiting for both agents to complete..."

BE_EXIT=0
FE_EXIT=0
wait $PID_BE || BE_EXIT=$?
wait $PID_FE || FE_EXIT=$?

if [[ "$BE_EXIT" -ne 0 ]]; then
  echo "ERROR: Backend generation failed (exit $BE_EXIT)"
  exit 1
fi
if [[ "$FE_EXIT" -ne 0 ]]; then
  echo "ERROR: Frontend generation failed (exit $FE_EXIT)"
  exit 1
fi
echo "Both agents completed successfully."
echo ""

# ── Step 3: Merge both branches back ─────────────────────
echo "═══ Merging worktrees → $MAIN_BRANCH ═══"
git merge --no-ff "$BE_BRANCH" -m "merge: phase-${PHASE_NUM} backend"
git merge --no-ff "$FE_BRANCH" -m "merge: phase-${PHASE_NUM} frontend"
echo ""

# ── Step 4: Gate check on merged result ───────────────────
echo "═══ Gate Check (merged) ═══"
bash scripts/gates/gate-all.sh
GATE_EXIT=$?
if [[ "$GATE_EXIT" -ne 0 ]]; then
  echo "GATE FAILED — aborting."
  exit 1
fi
echo ""

# ── Step 5: Diff review on merged result ──────────────────
echo "═══ Diff Review (merged) ═══"
bash scripts/review/diff-review.sh "$PHASE_NUM"
DREVIEW_EXIT=$?
if [[ "$DREVIEW_EXIT" -ne 0 ]]; then
  echo "DIFF REVIEW FAILED — aborting."
  exit 1
fi
echo ""

# ── Step 6: Semantic review via Agent ─────────────────────
echo "═══ Semantic Review ═══"
CHANGED_FILES=$(git diff --name-only HEAD~2)
REVIEW_RESULT=$(claude -p "You are code-reviewer. Review ONLY these changed files:
$CHANGED_FILES

Phase $PHASE_NUM scope: ${PHASE_SCOPE[*]}

Read CLAUDE.md and spec/01-constraints.md.
Check all hard rules against each changed file.
Flag any file outside scope as CRITICAL (scope-violation).
Output structured findings. End with REVIEW PASSED or REVIEW FAILED: N critical, M warnings." \
  --agent code-reviewer \
  --output-format text)

echo "$REVIEW_RESULT"
echo ""

if echo "$REVIEW_RESULT" | grep -q "REVIEW FAILED"; then
  echo "SEMANTIC REVIEW FAILED — aborting."
  exit 1
fi

# ── Step 7: Squash all merge commits into one ─────────────
# Use PRE_MERGE_HEAD (recorded before merges) for precise squash
# This avoids the fragile HEAD~N counting
echo "═══ Final Commit ═══"
git reset --soft "$PRE_MERGE_HEAD"
git commit -m "feat(phase-${PHASE_NUM}): ${PHASE_TITLE} — parallel verified"

echo ""
echo "════════════════════════════════════════"
echo "Phase $PHASE_NUM COMPLETE (parallel): $PHASE_TITLE"
echo "════════════════════════════════════════"
