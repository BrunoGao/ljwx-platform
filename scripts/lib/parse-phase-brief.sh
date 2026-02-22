#!/usr/bin/env bash
# Parse YAML front-matter from a Phase Brief file.
# Usage: source scripts/lib/parse-phase-brief.sh <phase-brief-path>
#   Exports: PHASE_NUM, PHASE_TITLE, TARGET_BACKEND, TARGET_FRONTEND, PHASE_SCOPE (array)

_BRIEF_PATH="${1:?Usage: source parse-phase-brief.sh <path-to-phase-XX.md>}"

if [[ ! -f "$_BRIEF_PATH" ]]; then
  echo "ERROR: Phase brief not found: $_BRIEF_PATH" >&2
  return 1 2>/dev/null || exit 1
fi

# Extract YAML block between first pair of --- markers (skip first line, stop before second ---)
_YAML=$(awk '/^---$/{n++;if(n==1){next};if(n==2){exit}} n==1{print}' "$_BRIEF_PATH")

if [[ -z "$_YAML" ]]; then
  echo "ERROR: No YAML front-matter found in $_BRIEF_PATH" >&2
  echo "       Every phase brief must begin with a --- YAML block." >&2
  return 1 2>/dev/null || exit 1
fi

PHASE_NUM=$(echo "$_YAML" | grep '^phase:' | awk '{print $2}')
PHASE_TITLE=$(echo "$_YAML" | grep '^title:' | sed 's/^title:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
TARGET_BACKEND=$(echo "$_YAML" | grep 'backend:' | awk '{print $2}' | head -1)
TARGET_FRONTEND=$(echo "$_YAML" | grep 'frontend:' | awk '{print $2}' | head -1)

# Parse scope list into array — use sed instead of BASH_REMATCH for portability
PHASE_SCOPE=()
_in_scope=false
while IFS= read -r _line; do
  if echo "$_line" | grep -q '^scope:'; then
    _in_scope=true
    continue
  fi
  if $_in_scope; then
    if echo "$_line" | grep -qE '^[[:space:]]*-[[:space:]]+'; then
      _entry=$(echo "$_line" | sed 's/^[[:space:]]*-[[:space:]]*//')
      # Strip surrounding quotes if present
      _entry="${_entry%\"}"
      _entry="${_entry#\"}"
      PHASE_SCOPE+=("$_entry")
    else
      _in_scope=false
    fi
  fi
done <<< "$_YAML"

export PHASE_NUM PHASE_TITLE TARGET_BACKEND TARGET_FRONTEND PHASE_SCOPE
