#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# diff-review.sh — 增量 scope 检查 + 变更文件快速扫描
# 与 gate-rules.sh 互补：diff-review 检查增量，gate-rules 检查全量
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PHASE_NUM="${1:?Usage: diff-review.sh <phase-number>}"
PRE_PHASE_FILE="${2:-}"   # optional: file listing changes that existed before this phase
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_BRIEF="spec/phase/phase-$(printf '%02d' "$PHASE_NUM").md"
if [[ ! -f "$PHASE_BRIEF" ]]; then
  echo "  WARN: $PHASE_BRIEF not found — skipping diff-review"
  exit 0
fi

# Parse scope from front-matter
PHASE_SCOPE=()
IN_SCOPE=false
while IFS= read -r line; do
  if [[ "$line" =~ ^scope: ]]; then
    IN_SCOPE=true
    continue
  fi
  if $IN_SCOPE; then
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      ENTRY="${BASH_REMATCH[1]}"
      ENTRY="${ENTRY%\"}"
      ENTRY="${ENTRY#\"}"
      PHASE_SCOPE+=("$ENTRY")
    else
      break
    fi
  fi
done < <(sed -n '/^---$/,/^---$/p' "$PHASE_BRIEF" | sed '1d;$d')

CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
if [[ -z "$CHANGED_FILES" ]]; then
  echo "  diff-review: No changed files"
  exit 0
fi

ERRORS=0

# ── Scope check: every changed file must match at least one scope pattern ──
echo "[Scope Check] Phase $PHASE_NUM"
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  MATCHED=false
  for pattern in "${PHASE_SCOPE[@]}"; do
    # Handle glob patterns
    if [[ "$pattern" == *"**"* ]]; then
      # Convert ** glob to regex
      REGEX=$(echo "$pattern" | sed 's/\*\*/.*/' | sed 's/\*/[^\/]*/')
      if [[ "$file" =~ ^$REGEX ]]; then
        MATCHED=true
        break
      fi
    elif [[ "$pattern" == *"*"* ]]; then
      REGEX=$(echo "$pattern" | sed 's/\*/[^\/]*/')
      if [[ "$file" =~ ^$REGEX ]]; then
        MATCHED=true
        break
      fi
    else
      if [[ "$file" == "$pattern" ]]; then
        MATCHED=true
        break
      fi
    fi
  done
  if ! $MATCHED; then
    # Allow common files that any phase might touch
    case "$file" in
      PHASE_MANIFEST.txt|CLAUDE.md|.gitignore) continue ;;
    esac
    # Skip files that were already changed before this phase started
    if [[ -n "$PRE_PHASE_FILE" ]] && grep -qxF "$file" "$PRE_PHASE_FILE" 2>/dev/null; then
      continue
    fi
    echo "  CRITICAL: $file — outside Phase $PHASE_NUM scope"
    ((ERRORS++))
  fi
done <<< "$CHANGED_FILES"

# ── Quick rule spot-check on changed files only ──
echo ""
echo "[Quick Spot-Check] Changed files"

# Caret in changed package.json files
PKG_FILES=$(echo "$CHANGED_FILES" | grep 'package.json' || true)
for f in $PKG_FILES; do
  [[ -f "$f" ]] || continue
  if grep -q '"\^' "$f"; then
    echo "  CRITICAL: $f contains caret (^)"
    ((ERRORS++))
  fi
done

# IF NOT EXISTS in changed SQL files
SQL_FILES=$(echo "$CHANGED_FILES" | grep '\.sql$' || true)
for f in $SQL_FILES; do
  [[ -f "$f" ]] || continue
  if grep -qi 'IF NOT EXISTS' "$f"; then
    echo "  CRITICAL: $f contains IF NOT EXISTS"
    ((ERRORS++))
  fi
done

# 'any' in changed TS/Vue files
TS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(ts|vue)$' || true)
for f in $TS_FILES; do
  [[ -f "$f" ]] || continue
  if grep -Pq '(?<!//.*)(:\s*any\b|as\s+any\b)' "$f"; then
    echo "  CRITICAL: $f contains TypeScript 'any'"
    ((ERRORS++))
  fi
done

# ── Summary ──
echo ""
echo "════════════════════════════════════════════════════"
echo "  diff-review: ERRORS=$ERRORS"
if [[ $ERRORS -gt 0 ]]; then
  echo "  diff-review: FAILED"
  exit 1
fi
echo "  diff-review: PASSED"
exit 0
