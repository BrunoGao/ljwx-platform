#!/usr/bin/env bash
# Flyway Repair Script
# Repairs the Flyway schema history to match current migration files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🔧 Running Flyway repair..."

# Run Maven Flyway repair
mvn flyway:repair -f pom.xml -q

echo "✅ Flyway repair completed"
