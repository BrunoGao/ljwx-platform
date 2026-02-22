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
BE_BRANCH="phase-${PHASE_NUM}-backend"
FE_BRANCH="phase-${PHASE_NUM}-frontend"
BE_WORKTREE="/tmp/ljwx-worktree-be-${PHASE_NUM}"
FE_WORKTREE="/tmp/ljwx-worktree-fe-${PHASE_NUM}"

# ── Cleanup on exit ───────────────────────────────────────
cleanup() {
  echo ""
  echo "Cleaning up worktrees..."
  git worktree remove "$BE_WORKTREE" --force 2>/dev/null || true
  git worktree remove "$FE_WORKTREE" --force 2>/dev/null || true
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
git branch "$BE_BRANCH" HEAD
git branch "$FE_BRANCH" HEAD
git worktree add "$BE_WORKTREE" "$BE_BRANCH"
git worktree add "$FE_WORKTREE" "$FE_BRANCH"
echo "  Backend worktree: $BE_WORKTREE ($BE_BRANCH)"
echo "  Frontend worktree: $FE_WORKTREE ($FE_BRANCH)"
echo ""

# ── Step 2: Parallel generation ───────────────────────────
echo "═══ Parallel Generation — Phase $PHASE_NUM ═══"

(
  cd "$BE_WORKTREE"
  echo "[BE] Starting backend generation..."
  claude -p "You are backend-builder. Execute Phase $PHASE_NUM backend tasks.
Read CLAUDE.md, spec/01-constraints.md, spec/08-output-rules.md, and $PHASE_BRIEF.
Generate ONLY backend files (.java, pom.xml, .xml, .yml, .sql, .properties).
Do NOT generate any frontend files (.vue, .ts, .json for node, .css, .html).
Follow spec/08-output-rules.md for output format." \
    --agent backend-builder \
    --output-format text
  git add -A
  git commit -m "wip: phase-${PHASE_NUM} backend" --allow-empty
  echo "[BE] Done."
) &
PID_BE=$!

(
  cd "$FE_WORKTREE"
  echo "[FE] Starting frontend generation..."
  claude -p "You are frontend-builder. Execute Phase $PHASE_NUM frontend tasks.
Read CLAUDE.md, spec/06-frontend-config.md, spec/08-output-rules.md, and $PHASE_BRIEF.
Generate ONLY frontend files (.vue, .ts, package.json, .scss, .html, tsconfig*.json).
Do NOT generate any backend files (.java, pom.xml, .sql, .yml backend configs).
Follow spec/08-output-rules.md for output format." \
    --agent frontend-builder \
    --output-format text
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

# ── Step 7: Squash merge commits into one ─────────────────
echo "═══ Final Commit ═══"
git reset --soft HEAD~2
git commit -m "feat(phase-${PHASE_NUM}): ${PHASE_TITLE} — parallel verified"

echo ""
echo "════════════════════════════════════════"
echo "Phase $PHASE_NUM COMPLETE (parallel): $PHASE_TITLE"
echo "════════════════════════════════════════"
