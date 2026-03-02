#!/usr/bin/env bash
# apply-baseline.sh — import local development baseline SQL into target DB
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ljwx_platform}"
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

BASELINE_VERSION_RAW="${BASELINE_VERSION:-52}"
if ! [[ "$BASELINE_VERSION_RAW" =~ ^[0-9]+$ ]]; then
  echo "[FATAL] BASELINE_VERSION must be numeric, got: $BASELINE_VERSION_RAW"
  exit 1
fi
BASELINE_VERSION_PADDED="$(printf "%03d" "$((10#$BASELINE_VERSION_RAW))")"
BASELINE_FILE="${BASELINE_FILE:-$PROJECT_ROOT/ljwx-platform-app/src/main/resources/db/baseline/V${BASELINE_VERSION_PADDED}__baseline.sql}"

if ! command -v psql >/dev/null 2>&1; then
  echo "[FATAL] psql not found"
  exit 1
fi
if [[ ! -f "$BASELINE_FILE" ]]; then
  echo "[FATAL] baseline file not found: $BASELINE_FILE"
  echo "        generate one first: bash scripts/generate-baseline.sh"
  exit 1
fi

export PGPASSWORD="$DB_PASSWORD"

echo "[INFO] Importing baseline into $DB_NAME"
echo "[INFO] Baseline file: $BASELINE_FILE"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$BASELINE_FILE" >/dev/null
echo "[OK] Baseline import completed"
