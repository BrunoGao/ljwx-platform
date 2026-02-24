#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# phase-execute.sh — 单 Phase 执行器（含重试、manifest 写入、追溯日志）
# 用法: bash scripts/phase-execute.sh <phase-number> [--skip-preflight]
#
# 流程: preflight → 解析 Phase Brief → Claude 生成 → gate-all → 重试(×3)
#       → diff-review → code-reviewer → 写 PHASE_MANIFEST.txt → git commit
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PHASE_NUM="${1:?Usage: phase-execute.sh <phase-number> [--skip-preflight]}"
SKIP_PREFLIGHT="${2:-}"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"

PHASE_PADDED=$(printf '%02d' "$PHASE_NUM")
PHASE_BRIEF="spec/phase/phase-${PHASE_PADDED}.md"
LOG_DIR="logs/phase-${PHASE_PADDED}"
MAX_RETRIES=3

mkdir -p "$LOG_DIR"

if [[ ! -f "$PHASE_BRIEF" ]]; then
  echo "ERROR: $PHASE_BRIEF not found"
  exit 1
fi

# ── Parse Phase Brief ──────────────────────────────────────
source scripts/lib/parse-phase-brief.sh "$PHASE_BRIEF"
echo "════════════════════════════════════════"
echo "Phase $PHASE_NUM: $PHASE_TITLE"
echo "  Backend: $TARGET_BACKEND | Frontend: $TARGET_FRONTEND"
echo "  Scope files: ${#PHASE_SCOPE[@]}"
echo "════════════════════════════════════════"
echo ""

# ── Update CLAUDE.md current phase marker ─────────────────
# Preserves the title portion: "Phase: 0 (Skeleton) — ..." → "Phase: N ..."
sed -i.bak "s/^Phase: [0-9][0-9]*/Phase: $PHASE_NUM/" CLAUDE.md && rm -f CLAUDE.md.bak

# ── Step 0: Preflight ─────────────────────────────────────
if [[ "$SKIP_PREFLIGHT" != "--skip-preflight" ]]; then
  echo "═══ STEP 0: Preflight Check ═══"
  bash scripts/preflight/preflight-check.sh
  echo ""
fi

# Record files already changed before this phase starts (for diff-review baseline)
PRE_PHASE_FILE=$(mktemp)
git diff --name-only HEAD > "$PRE_PHASE_FILE" 2>/dev/null || true

# ── Build generation prompt ───────────────────────────────
BUILD_PROMPT="You are executing Phase $PHASE_NUM of the LJWX Platform.

Phase title: $PHASE_TITLE
Backend: $TARGET_BACKEND | Frontend: $TARGET_FRONTEND

## Your task
1. Read CLAUDE.md for all hard rules
2. Read spec/phase/${PHASE_BRIEF} for scope, deliverables, and acceptance criteria
3. Read only the spec files referenced in the Phase Brief reading list
4. Generate EVERY file listed in the scope section — complete content, no placeholders
5. After generating backend files: run mvn clean compile -f pom.xml and fix all errors
6. After generating frontend files: run pnpm run type-check and fix all type errors
7. Write a PHASE_MANIFEST.txt entry in this exact format:

## PHASE $PHASE_NUM
Title: $PHASE_TITLE
Completed: \$(date -u +%Y-%m-%dT%H:%M:%SZ)
Files:
$(for f in "${PHASE_SCOPE[@]}"; do echo "  - $f"; done)
Status: PENDING

8. Then run: bash scripts/gates/gate-all.sh $PHASE_NUM
9. If any gate FAILS, fix every FAIL and re-run gates until all PASS
10. Once gates PASS, update the Status in PHASE_MANIFEST.txt to: PASSED
11. Do NOT stop until all gates pass and PHASE_MANIFEST.txt is updated

Follow spec/08-output-rules.md for output format strictly."

# ── Step 1-2: Generation with retry ───────────────────────
RETRY=0
GATE_PASSED=false

while [[ $RETRY -lt $MAX_RETRIES ]]; do
  ATTEMPT=$((RETRY + 1))
  echo "═══ STEP 1: Generation — Attempt $ATTEMPT / $MAX_RETRIES ═══"

  ATTEMPT_LOG="$LOG_DIR/attempt-${ATTEMPT}.log"

  if [[ $RETRY -eq 0 ]]; then
    PROMPT="$BUILD_PROMPT"
  else
    # Collect gate failures for retry prompt
    GATE_OUTPUT=$(bash scripts/gates/gate-all.sh "$PHASE_NUM" 2>&1 || true)
    PROMPT="Phase $PHASE_NUM gate check FAILED on attempt $RETRY. Fix ALL issues below:

$GATE_OUTPUT

After fixing:
1. Re-run: bash scripts/gates/gate-all.sh $PHASE_NUM
2. Ensure ALL gates PASS
3. Update PHASE_MANIFEST.txt Status to PASSED
4. Do not stop until gates pass."
  fi

  # Run claude in headless mode
  # --agent flag is used to activate the agent definition from .claude/agents/
  if [[ "$TARGET_BACKEND" == "true" && "$TARGET_FRONTEND" != "true" ]]; then
    claude -p "$PROMPT" \
      --agent backend-builder \
      --max-turns 80 \
      --output-format text \
      2>&1 | tee "$ATTEMPT_LOG"
  elif [[ "$TARGET_FRONTEND" == "true" && "$TARGET_BACKEND" != "true" ]]; then
    claude -p "$PROMPT" \
      --agent frontend-builder \
      --max-turns 60 \
      --output-format text \
      2>&1 | tee "$ATTEMPT_LOG"
  else
    # Both or neither: use no specific agent (full Claude)
    claude -p "$PROMPT" \
      --max-turns 80 \
      --output-format text \
      2>&1 | tee "$ATTEMPT_LOG"
  fi

  echo ""
  echo "═══ STEP 2: Gate Check — Attempt $ATTEMPT ═══"
  if bash scripts/gates/gate-all.sh "$PHASE_NUM" 2>&1 | tee "$LOG_DIR/gate-attempt-${ATTEMPT}.log"; then
    GATE_PASSED=true
    echo "Gates PASSED on attempt $ATTEMPT."
    break
  else
    echo "Gates FAILED on attempt $ATTEMPT."
    RETRY=$((RETRY + 1))
    if [[ $RETRY -ge $MAX_RETRIES ]]; then
      echo "All $MAX_RETRIES attempts exhausted. Phase $PHASE_NUM FAILED."
      echo "Phase $PHASE_NUM FAILED — $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> logs/failed.log
      exit 1
    fi
    echo "Retrying with gate error feedback..."
    echo ""
  fi
done

if [[ "$GATE_PASSED" != "true" ]]; then
  exit 1
fi

# ── Step 3: Zero-token diff review ────────────────────────
echo "═══ STEP 3: Diff Review (zero-token rules scan) ═══"
bash scripts/review/diff-review.sh "$PHASE_NUM" "$PRE_PHASE_FILE" 2>&1 | tee "$LOG_DIR/diff-review.log"
REVIEW_EXIT=${PIPESTATUS[0]}
if [[ "$REVIEW_EXIT" -ne 0 ]]; then
  echo "DIFF REVIEW FAILED — aborting."
  exit 1
fi
echo ""

# ── Step 4: Semantic review via code-reviewer agent ───────
echo "═══ STEP 4: Semantic Review ═══"
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
if [[ -n "$CHANGED_FILES" ]]; then
  REVIEW_RESULT=$(claude -p "You are the code-reviewer. Review ONLY these changed files:
$CHANGED_FILES

Phase $PHASE_NUM allowed scope:
$(for f in "${PHASE_SCOPE[@]}"; do echo "  $f"; done)

Read CLAUDE.md and spec/01-constraints.md.
Check all hard rules. Flag files outside scope as CRITICAL (scope-violation).
Output: [CRITICAL|WARNING|INFO] <file>:<line> — <rule-id> — <description>
End with: REVIEW PASSED or REVIEW FAILED: N critical, M warnings." \
    --agent code-reviewer \
    --max-turns 20 \
    --output-format text \
    2>&1 | tee "$LOG_DIR/semantic-review.log")

  echo "$REVIEW_RESULT"
  echo ""

  if echo "$REVIEW_RESULT" | grep -q "REVIEW FAILED"; then
    echo "Semantic review found CRITICAL issues — aborting."
    exit 1
  fi
else
  echo "No changed files to review."
fi

# ── Step 5: Ensure PHASE_MANIFEST.txt is written ──────────
echo "═══ STEP 5: PHASE_MANIFEST.txt ═══"
MANIFEST="PHASE_MANIFEST.txt"
MARKER="## PHASE $PHASE_NUM"

if grep -q "$MARKER" "$MANIFEST" 2>/dev/null; then
  # Update status to PASSED if not already
  sed -i.bak "/$MARKER/,/^## PHASE/{s/Status: PENDING/Status: PASSED/}" "$MANIFEST" && rm -f "${MANIFEST}.bak"
  echo "  Manifest entry updated: $MARKER → PASSED"
else
  # Write new entry
  {
    echo ""
    echo "$MARKER"
    echo "Title: $PHASE_TITLE"
    echo "Completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Files:"
    for f in "${PHASE_SCOPE[@]}"; do
      echo "  - $f"
    done
    echo "Status: PASSED"
  } >> "$MANIFEST"
  echo "  Manifest entry written: $MARKER"
fi

# ── Step 6: Git commit ────────────────────────────────────
echo "═══ STEP 6: Git Commit ═══"
rm -f "$PRE_PHASE_FILE"
git add -A
git commit -m "feat(phase-${PHASE_NUM}): ${PHASE_TITLE} — auto-verified" || true
echo ""

echo "════════════════════════════════════════"
echo "Phase $PHASE_NUM COMPLETE: $PHASE_TITLE"
echo "Logs: $LOG_DIR/"
echo "════════════════════════════════════════"
