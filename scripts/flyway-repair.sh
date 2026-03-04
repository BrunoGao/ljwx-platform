#!/usr/bin/env bash
# Flyway repair wrapper.
# Run from aggregator root so dependent modules are resolvable in CI runners.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🔧 Running Flyway repair on ljwx-platform-app (with -am)"
mvn -q -f pom.xml -pl ljwx-platform-app -am flyway:repair
echo "✅ Flyway repair completed"
