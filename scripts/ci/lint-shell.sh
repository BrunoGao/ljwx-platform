#!/usr/bin/env bash
set -euo pipefail

# CI: syntax-check all shell scripts in the project.
# Uses bash -n for all .sh files.
# Uses shellcheck if available (warning level, non-blocking).

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ERRORS=0

echo "=== Shell Script Lint ==="
echo ""

# Collect all .sh files
while IFS= read -r -d '' SCRIPT_FILE; do
    REL="${SCRIPT_FILE#"$PROJECT_ROOT"/}"
    if bash -n "$SCRIPT_FILE" 2>/dev/null; then
        echo "  [OK]   $REL"
    else
        echo "  [FAIL] $REL — syntax error:"
        bash -n "$SCRIPT_FILE" 2>&1 | sed 's/^/         /'
        ERRORS=$((ERRORS + 1))
    fi
done < <(find \
    "$PROJECT_ROOT/scripts" \
    "$PROJECT_ROOT/.claude/hooks" \
    -type f -name "*.sh" -print0 2>/dev/null)

# shellcheck if available (informational only)
if command -v shellcheck >/dev/null 2>&1; then
    echo ""
    echo "--- shellcheck (warnings only, non-blocking) ---"
    while IFS= read -r -d '' SCRIPT_FILE; do
        REL="${SCRIPT_FILE#"$PROJECT_ROOT"/}"
        if ! shellcheck -S warning -e SC2148 "$SCRIPT_FILE" 2>/dev/null; then
            echo "  [WARN] $REL has shellcheck findings"
        fi
    done < <(find \
        "$PROJECT_ROOT/scripts" \
        "$PROJECT_ROOT/.claude/hooks" \
        -type f -name "*.sh" -print0 2>/dev/null)
else
    echo ""
    echo "  [INFO] shellcheck not installed — install with: brew install shellcheck"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "LINT FAILED: $ERRORS script(s) have bash syntax errors"
    exit 1
fi

echo "LINT PASSED"
exit 0
