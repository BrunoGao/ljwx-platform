#!/usr/bin/env bash
# Stop hook — lightweight gate, all checks finish in <100ms.
# NO compilation, NO pnpm, NO network. Only: file-exists, grep, git-diff.
# Compilation is handled by the gate scripts inside phase-execute.sh.

set -euo pipefail

INPUT=$(cat)

# Prevent infinite loop: Claude Code sets stop_hook_active=true on retry
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [[ "$STOP_ACTIVE" == "true" ]]; then
  exit 0
fi

# Resolve project root
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$PROJECT_DIR"

# Determine current phase number from CLAUDE.md
CURRENT_PHASE=$(sed -n 's/^Phase:[[:space:]]*\([0-9][0-9]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -1 || echo "")
if [[ -z "$CURRENT_PHASE" ]]; then
  exit 0
fi

PHASE_BRIEF="spec/phase/phase-$(printf '%02d' "$CURRENT_PHASE").md"
[[ -f "$PHASE_BRIEF" ]] || exit 0

BLOCK_REASON=""

# Check 1: Concrete scope files from Phase Brief YAML front-matter (<10ms)
IN_SCOPE=false
MISSING_FILES=()
while IFS= read -r line; do
  if echo "$line" | grep -q '^scope:'; then
    IN_SCOPE=true
    continue
  fi
  if $IN_SCOPE; then
    if echo "$line" | grep -qE '^[[:space:]]*-[[:space:]]+'; then
      entry=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
      # Only check concrete paths (no glob wildcards)
      if echo "$entry" | grep -qF '*'; then
        : # has wildcard, skip
      elif [[ "$(basename "$entry")" == .env* ]]; then
        : # .env* files cannot be written by Claude Code (system sandbox); user creates manually
      else
        [[ -f "$entry" ]] || MISSING_FILES+=("$entry")
      fi
    else
      IN_SCOPE=false
    fi
  fi
done < <(awk '/^---$/{n++;if(n==1){next};if(n==2){exit}} n==1{print}' "$PHASE_BRIEF")

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  BLOCK_REASON="Missing expected scope files: $(printf '%s ' "${MISSING_FILES[@]}")"
fi

# Check 2: Quick grep on git-changed files (<50ms)
CHANGED=$(git diff --name-only HEAD 2>/dev/null || true)
if [[ -n "$CHANGED" ]]; then
  # Caret in package.json
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ -f "$f" ]] && grep -q '"^' "$f" 2>/dev/null; then
      BLOCK_REASON="${BLOCK_REASON}Caret (^) version found in $f. "
    fi
  done < <(echo "$CHANGED" | grep 'package\.json' || true)

  # IF NOT EXISTS in SQL migration files
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ -f "$f" ]] && grep -qi 'IF NOT EXISTS' "$f" 2>/dev/null; then
      BLOCK_REASON="${BLOCK_REASON}IF NOT EXISTS in $f (Flyway rule). "
    fi
  done < <(echo "$CHANGED" | grep '\.sql$' || true)

  # Wrong env var in TS/Vue files
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ -f "$f" ]] && grep -qE 'VITE_API_BASE_URL|VITE_BASE_API' "$f" 2>/dev/null; then
      BLOCK_REASON="${BLOCK_REASON}Wrong env var in $f (must be VITE_APP_BASE_API). "
    fi
  done < <(echo "$CHANGED" | grep -E '\.(ts|vue)$' || true)
fi

if [[ -n "$BLOCK_REASON" ]]; then
  SAFE=$(printf '%s' "$BLOCK_REASON" | sed 's/"/\\"/g')
  printf '{"decision":"block","reason":"Stop gate: %s"}\n' "$SAFE"
  exit 0
fi

exit 0
