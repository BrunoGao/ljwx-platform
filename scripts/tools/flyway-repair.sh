#!/usr/bin/env bash
# Backward-compatible entrypoint for existing scripts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

bash "$PROJECT_ROOT/scripts/flyway-repair.sh"
