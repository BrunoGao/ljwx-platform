#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-manifest.sh — Phase-local manifest 与 scope 文件检查
#
# 检查项：
#   1. PHASE_MANIFEST.txt 存在且非空
#   2. 当前 Phase 的 section 存在
#   3. Phase Brief 中 scope 列出的具体文件全部存在
#   4. Phase Brief 文件本身存在且有 YAML front-matter
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0

# ── Determine current phase ──
CURRENT_PHASE=$(grep -oP 'Current Phase:\s*\K\d+' CLAUDE.md 2>/dev/null || echo "")
if [[ -z "$CURRENT_PHASE" ]]; then
  echo "  WARN: Cannot determine Current Phase from CLAUDE.md — skipping manifest check"
  exit 0
fi

PHASE_PADDED=$(printf '%02d' "$CURRENT_PHASE")
PHASE_BRIEF="spec/phase/phase-${PHASE_PADDED}.md"

# ── Check 1: Phase Brief file exists ──
if [[ ! -f "$PHASE_BRIEF" ]]; then
  echo "  FAIL: Phase Brief $PHASE_BRIEF not found"
  ((ERRORS++))
else
  # Check YAML front-matter exists
  if ! head -1 "$PHASE_BRIEF" | grep -q '^---$'; then
    echo "  FAIL: $PHASE_BRIEF missing YAML front-matter (must start with ---)"
    ((ERRORS++))
  fi

  # Check required front-matter fields
  FRONT_MATTER=$(sed -n '/^---$/,/^---$/p' "$PHASE_BRIEF" | sed '1d;$d')
  for FIELD in "phase:" "title:" "targets:" "scope:"; do
    if ! echo "$FRONT_MATTER" | grep -q "$FIELD"; then
      echo "  FAIL: $PHASE_BRIEF front-matter missing field: $FIELD"
      ((ERRORS++))
    fi
  done
fi

# ── Check 2: PHASE_MANIFEST.txt exists and has current phase section ──
if [[ ! -f "PHASE_MANIFEST.txt" ]]; then
  echo "  FAIL: PHASE_MANIFEST.txt not found"
  ((ERRORS++))
elif [[ ! -s "PHASE_MANIFEST.txt" ]]; then
  echo "  FAIL: PHASE_MANIFEST.txt is empty"
  ((ERRORS++))
else
  MANIFEST_MARKER="## PHASE $CURRENT_PHASE"
  if ! grep -q "$MANIFEST_MARKER" PHASE_MANIFEST.txt; then
    echo "  FAIL: PHASE_MANIFEST.txt missing section: $MANIFEST_MARKER"
    ((ERRORS++))
  fi
fi

# ── Check 3: All concrete scope files exist ──
if [[ -f "$PHASE_BRIEF" ]]; then
  SCOPE_BLOCK=$(sed -n '/^scope:/,/^[a-z]/p' "$PHASE_BRIEF" | grep '^\s*-' || true)
  if [[ -z "$SCOPE_BLOCK" ]]; then
    echo "  WARN: No scope entries found in $PHASE_BRIEF"
  else
    while IFS= read -r line; do
      # Extract path from "  - \"path\"" or "  - path"
      ENTRY=$(echo "$line" | sed 's/^\s*-\s*//; s/^"//; s/"$//')
      # Skip glob patterns
      if [[ "$ENTRY" == *"*"* || "$ENTRY" == *"**"* ]]; then
        continue
      fi
      # Skip empty
      [[ -z "$ENTRY" ]] && continue
      if [[ ! -f "$ENTRY" && ! -d "$ENTRY" ]]; then
        echo "  FAIL: Scope file missing: $ENTRY"
        ((ERRORS++))
      fi
    done <<< "$SCOPE_BLOCK"
  fi
fi

# ── Summary ──
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-manifest: $ERRORS errors"
  exit 1
fi
echo "  gate-manifest: PASSED"
exit 0
