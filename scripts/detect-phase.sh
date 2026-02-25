#!/usr/bin/env bash
set -euo pipefail

# Conservative phase detector:
# - Input: file path containing changed files (one per line), or stdin.
# - Output: phase number if confidently detected, otherwise empty.
# - Current policy prefers full gate execution over false narrowing.

INPUT_FILE="${1:-}"

if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo ""
    exit 0
  fi
  mapfile -t changed_files < "$INPUT_FILE"
else
  mapfile -t changed_files
fi

if [[ ${#changed_files[@]} -eq 0 ]]; then
  echo ""
  exit 0
fi

declare -A phase_hits=()
for file in "${changed_files[@]}"; do
  if [[ "$file" =~ ^spec/phase/phase-([0-9]{1,2})\.md$ ]]; then
    phase="${BASH_REMATCH[1]}"
    phase_hits["$((10#$phase))"]=1
  fi
done

if [[ ${#phase_hits[@]} -eq 1 ]]; then
  for phase in "${!phase_hits[@]}"; do
    echo "$phase"
    exit 0
  done
fi

echo ""
