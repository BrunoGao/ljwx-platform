#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ERRORS=0

echo "=== YAML Validation ==="
echo ""

if ! command -v python3 >/dev/null 2>&1; then
  echo "  [SKIP] python3 not found — YAML validation skipped"
  exit 0
fi

if ! python3 -c "import yaml" 2>/dev/null; then
  echo "  [SKIP] PyYAML not installed — run: pip install pyyaml"
  exit 0
fi

while IFS= read -r -d '' YAML_FILE; do
  REL="${YAML_FILE#"$PROJECT_ROOT"/}"
  if python3 -c '
import sys, yaml
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        yaml.safe_load(f)
except yaml.YAMLError as e:
    print(e)
    raise
' "$YAML_FILE" >/dev/null 2>&1; then
    echo "  [OK]   $REL"
  else
    ERROR_MSG=$(python3 -c '
import sys, yaml
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        yaml.safe_load(f)
except yaml.YAMLError as e:
    print(e)
' "$YAML_FILE" 2>&1 || true)
    echo "  [FAIL] $REL — $ERROR_MSG"
    ERRORS=$((ERRORS + 1))
  fi
done < <(find \
  "$PROJECT_ROOT/prompts" \
  "$PROJECT_ROOT/.github/workflows" \
  "$PROJECT_ROOT/.github/ISSUE_TEMPLATE" \
  -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 2>/dev/null)

if [[ -f "$PROJECT_ROOT/.github/release.yml" ]]; then
  if python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], "r", encoding="utf-8"))' "$PROJECT_ROOT/.github/release.yml" >/dev/null 2>&1; then
    echo "  [OK]   .github/release.yml"
  else
    ERROR_MSG=$(python3 -c 'import sys, yaml
try:
    yaml.safe_load(open(sys.argv[1], "r", encoding="utf-8"))
except yaml.YAMLError as e:
    print(e)
' "$PROJECT_ROOT/.github/release.yml" 2>&1 || true)
    echo "  [FAIL] .github/release.yml — $ERROR_MSG"
    ERRORS=$((ERRORS + 1))
  fi
fi

echo ""
if [[ "$ERRORS" -gt 0 ]]; then
  echo "YAML VALIDATION FAILED: $ERRORS file(s) invalid"
  exit 1
fi

echo "YAML VALIDATION PASSED"
