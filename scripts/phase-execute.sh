#!/usr/bin/env bash
set -euo pipefail

PHASE_NUM="${1:?Usage: phase-execute.sh <phase-number> [--skip-preflight]}"
SKIP_PREFLIGHT="${2:-}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_BRIEF="spec/phase/phase-$(printf '%02d' "$PHASE_NUM").md"
if [[ ! -f "$PHASE_BRIEF" ]]; then
  echo "ERROR: $PHASE_BRIEF not found"
  exit 1
fi

# ── Parse Phase Brief ─────────────────────────────────────
source scripts/lib/parse-phase-brief.sh "$PHASE_BRIEF"
echo "Phase $PHASE_NUM: $PHASE_TITLE"
echo "  Backend: $TARGET_BACKEND | Frontend: $TARGET_FRONTEND"
echo "  Scope: ${PHASE_SCOPE[*]}"
echo ""

# ── Step 0: Preflight ─────────────────────────────────────
if [[ "$SKIP_PREFLIGHT" != "--skip-preflight" ]]; then
  echo "═══ STEP 0: Preflight Check ═══"
  bash scripts/preflight/preflight-check.sh
  echo ""
fi

# ── Step 1a: Backend generation ───────────────────────────
if [[ "$TARGET_BACKEND" == "true" ]]; then
  echo "═══ STEP 1a: Backend Builder — Phase $PHASE_NUM ═══"
  claude -p "You are backend-builder. Execute Phase $PHASE_NUM.
Read CLAUDE.md, spec/01-constraints.md, and $PHASE_BRIEF.
Generate all backend files listed in the Phase Brief scope.
Follow spec/08-output-rules.md for output format.
After generating, run: bash scripts/gates/gate-compile.sh" \
    --agent backend-builder \
    --output-format json > "/tmp/ljwx-phase-${PHASE_NUM}-backend.json"
  echo "Backend generation complete."
  echo ""
fi

# ── Step 1b: Frontend generation ──────────────────────────
if [[ "$TARGET_FRONTEND" == "true" ]]; then
  echo "═══ STEP 1b: Frontend Builder — Phase $PHASE_NUM ═══"
  claude -p "You are frontend-builder. Execute Phase $PHASE_NUM.
Read CLAUDE.md, spec/06-frontend-config.md, and $PHASE_BRIEF.
Generate all frontend files listed in the Phase Brief scope.
Follow spec/08-output-rules.md for output format.
After generating, run: pnpm install && pnpm run type-check" \
    --agent frontend-builder \
    --output-format json > "/tmp/ljwx-phase-${PHASE_NUM}-frontend.json"
  echo "Frontend generation complete."
  echo ""
fi

# ── Step 2: Gate check ────────────────────────────────────
echo "═══ STEP 2: Gate Check ═══"
bash scripts/gates/gate-all.sh
GATE_EXIT=$?
if [[ "$GATE_EXIT" -ne 0 ]]; then
  echo "GATE FAILED — aborting."
  exit 1
fi
echo ""

# ── Step 3: Diff-driven hard rule scan ────────────────────
echo "═══ STEP 3: Diff Review (zero-token) ═══"
bash scripts/review/diff-review.sh "$PHASE_NUM"
REVIEW_EXIT=$?
if [[ "$REVIEW_EXIT" -ne 0 ]]; then
  echo "DIFF REVIEW FAILED — aborting."
  exit 1
fi
echo ""

# ── Step 4: Semantic review via Agent ─────────────────────
echo "═══ STEP 4: Semantic Review ═══"
CHANGED_FILES=$(git diff --name-only HEAD)
REVIEW_RESULT=$(claude -p "You are code-reviewer. Review ONLY these changed files:
$CHANGED_FILES

Phase $PHASE_NUM scope allows: ${PHASE_SCOPE[*]}

Read CLAUDE.md and spec/01-constraints.md.
For each file, check the review checklist.
Flag any file NOT in the allowed scope as CRITICAL.
Output each finding as:
[CRITICAL|WARNING|INFO] <file>:<line> — <rule-id> — <description> — <evidence>
End with: REVIEW PASSED or REVIEW FAILED: N critical, M warnings." \
  --agent code-reviewer \
  --output-format text)

echo "$REVIEW_RESULT"
echo ""

if echo "$REVIEW_RESULT" | grep -q "REVIEW FAILED"; then
  exit 1
fi

# ── Step 5: Commit ────────────────────────────────────────
echo "═══ STEP 5: Git Commit ═══"
git add -A
git commit -m "feat(phase-${PHASE_NUM}): ${PHASE_TITLE} — auto-verified"
echo ""
echo "════════════════════════════════════════"
echo "Phase $PHASE_NUM COMPLETE: $PHASE_TITLE"
echo "════════════════════════════════════════"
