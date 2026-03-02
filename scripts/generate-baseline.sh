#!/usr/bin/env bash
# generate-baseline.sh — generate a local development DB baseline SQL
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATION_DIR="${MIGRATION_DIR:-$PROJECT_ROOT/ljwx-platform-app/src/main/resources/db/migration}"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
BASE_DB_NAME="${DB_NAME:-ljwx_platform}"

BASELINE_VERSION_RAW="${BASELINE_VERSION:-52}"
if ! [[ "$BASELINE_VERSION_RAW" =~ ^[0-9]+$ ]]; then
  echo "[FATAL] BASELINE_VERSION must be numeric, got: $BASELINE_VERSION_RAW"
  exit 1
fi
BASELINE_VERSION_PADDED="$(printf "%03d" "$((10#$BASELINE_VERSION_RAW))")"

BASELINE_OUTPUT="${BASELINE_OUTPUT:-$PROJECT_ROOT/ljwx-platform-app/src/main/resources/db/baseline/V${BASELINE_VERSION_PADDED}__baseline.sql}"
BUILD_DB_NAME="${BUILD_DB_NAME:-${BASE_DB_NAME}_baseline_build}"
CLEANUP_BUILD_DB="${CLEANUP_BUILD_DB:-true}"

if ! command -v psql >/dev/null 2>&1; then
  echo "[FATAL] psql not found"
  exit 1
fi
if ! command -v pg_dump >/dev/null 2>&1; then
  echo "[FATAL] pg_dump not found"
  exit 1
fi
if [[ ! -d "$MIGRATION_DIR" ]]; then
  echo "[FATAL] migration directory not found: $MIGRATION_DIR"
  exit 1
fi

export PGPASSWORD="$DB_PASSWORD"
mkdir -p "$(dirname "$BASELINE_OUTPUT")"

cleanup() {
  if [[ "$CLEANUP_BUILD_DB" == "true" ]]; then
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -v ON_ERROR_STOP=1 -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$BUILD_DB_NAME'
  AND pid <> pg_backend_pid();
" >/dev/null 2>&1 || true
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $BUILD_DB_NAME;" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "[INFO] Building baseline from migrations <= V${BASELINE_VERSION_PADDED}"
echo "[INFO] Build DB: $BUILD_DB_NAME"
echo "[INFO] Output: $BASELINE_OUTPUT"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -v ON_ERROR_STOP=1 -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$BUILD_DB_NAME'
  AND pid <> pg_backend_pid();
" >/dev/null 2>&1 || true
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $BUILD_DB_NAME;" >/dev/null
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $BUILD_DB_NAME;" >/dev/null

collect_migrations() {
  local dir="$1"
  if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$PROJECT_ROOT" ls-files -- "$dir"/V*.sql 2>/dev/null | sort
  else
    find "$dir" -maxdepth 1 -type f -name 'V*.sql' | sort
  fi
}

mapfile -t MIGRATIONS < <(collect_migrations "$MIGRATION_DIR")
if [[ "${#MIGRATIONS[@]}" -eq 0 ]]; then
  echo "[FATAL] no migration files found in $MIGRATION_DIR"
  exit 1
fi

APPLIED=0
for file in "${MIGRATIONS[@]}"; do
  filename="$(basename "$file")"
  version="$(sed -nE 's/^V([0-9]{3})__.*/\1/p' <<<"$filename")"
  if [[ -z "$version" ]]; then
    continue
  fi
  if (( 10#$version > 10#$BASELINE_VERSION_PADDED )); then
    continue
  fi
  echo "[INFO] applying $filename"
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$BUILD_DB_NAME" -v ON_ERROR_STOP=1 -f "$file" >/dev/null
  APPLIED=$((APPLIED + 1))
done

if [[ "$APPLIED" -eq 0 ]]; then
  echo "[FATAL] no migrations were applied, check BASELINE_VERSION=$BASELINE_VERSION_PADDED"
  exit 1
fi

pg_dump \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USERNAME" \
  -d "$BUILD_DB_NAME" \
  --no-owner \
  --no-privileges \
  --format=plain \
  > "$BASELINE_OUTPUT"

echo "[OK] Baseline generated: $BASELINE_OUTPUT"
echo "[OK] Applied migrations count: $APPLIED"
