#!/usr/bin/env bash
set -euo pipefail

# CI: validate YAML files in the project using Python's yaml module.
# Checks prompts/ and .github/workflows/ directories.

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

# Find YAML files in known directories
while IFS= read -r -d '' YAML_FILE; do
    REL="${YAML_FILE#"$PROJECT_ROOT"/}"
    if python3 -c "
import yaml, sys
try:
    with open(sys.argv[1]) as fh:
        yaml.safe_load(fh)
except yaml.YAMLError as e:
    print(f'YAML error: {e}', file=sys.stderr)
    sys.exit(1)
" "$YAML_FILE" 2>/dev/null; then
        echo "  [OK]   $REL"
    else
        ERROR_MSG=$(python3 -c "
import yaml, sys
try:
    with open(sys.argv[1]) as fh:
        yaml.safe_load(fh)
except yaml.YAMLError as e:
    print(str(e))
" "$YAML_FILE" 2>&1 || true)
        echo "  [FAIL] $REL — $ERROR_MSG"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find \
    "$PROJECT_ROOT/prompts" \
    "$PROJECT_ROOT/.github/workflows" \
    -type f \( -name "*.yaml" -o -name "*.yml" \) -print0 2>/dev/null)

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "YAML VALIDATION FAILED: $ERRORS file(s) invalid"
    exit 1
fi

echo "YAML VALIDATION PASSED"
exit 0
