#!/usr/bin/env bash
# Flyway Repair Script
# Fixes checksum mismatches in flyway_schema_history table

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔧 Flyway Repair Tool"
echo "===================="
echo ""

cd "$PROJECT_ROOT/ljwx-platform-app"

echo "Running flyway:repair to fix checksum mismatches..."
mvn flyway:repair -q

if [ $? -eq 0 ]; then
    echo "✅ Flyway repair completed successfully"
    echo ""
    echo "Checksum mismatches have been resolved."
    echo "You can now run: bash scripts/gates/gate-all.sh 35"
else
    echo "❌ Flyway repair failed"
    exit 1
fi
