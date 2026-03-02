#!/usr/bin/env bash
# gate-baseline.sh — verify baseline assets and optional runtime import check
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0
WARNINGS=0

fail() { echo "  CRITICAL  $1"; ((ERRORS++)); }
warn() { echo "  WARNING   $1"; ((WARNINGS++)); }
info() { echo "  INFO      $1"; }

ENV_EXAMPLE=".env.example"
LOCAL_PROFILE="ljwx-platform-app/src/main/resources/application-local.yml"
MIGRATION_DIR="ljwx-platform-app/src/main/resources/db/migration"
BASELINE_DIR="ljwx-platform-app/src/main/resources/db/baseline"
GEN_SCRIPT="scripts/generate-baseline.sh"
APPLY_SCRIPT="scripts/apply-baseline.sh"
RESET_SCRIPT="scripts/reset-database.sh"

for required in "$ENV_EXAMPLE" "$LOCAL_PROFILE" "$MIGRATION_DIR" "$BASELINE_DIR" "$GEN_SCRIPT" "$APPLY_SCRIPT" "$RESET_SCRIPT"; do
  if [[ ! -e "$required" ]]; then
    fail "missing required file: $required"
  fi
done

if [[ ! -f "$ENV_EXAMPLE" || ! -f "$LOCAL_PROFILE" ]]; then
  echo "  gate-baseline: ERRORS=$ERRORS WARNINGS=$WARNINGS"
  echo "  gate-baseline: FAILED"
  exit 1
fi

ENV_BASELINE_VERSION="$(sed -nE 's/^[[:space:]]*FLYWAY_BASELINE_VERSION=([0-9]+).*/\1/p' "$ENV_EXAMPLE" | head -n1 || true)"
LOCAL_BASELINE_VERSION="$(sed -nE 's/^[[:space:]]*baseline-version:[[:space:]]*\$\{FLYWAY_BASELINE_VERSION:([0-9]+)\}.*/\1/p' "$LOCAL_PROFILE" | head -n1 || true)"

if [[ -z "$ENV_BASELINE_VERSION" ]]; then
  fail "cannot parse FLYWAY_BASELINE_VERSION from $ENV_EXAMPLE"
fi
if [[ -z "$LOCAL_BASELINE_VERSION" ]]; then
  fail "cannot parse flyway.baseline-version default from $LOCAL_PROFILE"
fi

if [[ -n "$ENV_BASELINE_VERSION" && -n "$LOCAL_BASELINE_VERSION" && "$ENV_BASELINE_VERSION" != "$LOCAL_BASELINE_VERSION" ]]; then
  fail "baseline version mismatch: .env.example=$ENV_BASELINE_VERSION, application-local.yml=$LOCAL_BASELINE_VERSION"
fi

BASELINE_VERSION="$ENV_BASELINE_VERSION"
if ! [[ "${BASELINE_VERSION:-}" =~ ^[0-9]+$ ]]; then
  fail "baseline version is not numeric: ${BASELINE_VERSION:-<empty>}"
fi

if [[ "$ERRORS" -eq 0 ]]; then
  BASELINE_VERSION_PADDED="$(printf "%03d" "$((10#$BASELINE_VERSION))")"
  BASELINE_FILE="$BASELINE_DIR/V${BASELINE_VERSION_PADDED}__baseline.sql"

  if [[ ! -f "$BASELINE_FILE" ]]; then
    fail "baseline file not found: $BASELINE_FILE"
  elif [[ ! -s "$BASELINE_FILE" ]]; then
    fail "baseline file is empty: $BASELINE_FILE"
  elif ! grep -q '^CREATE TABLE ' "$BASELINE_FILE"; then
    fail "baseline file has no CREATE TABLE statements: $BASELINE_FILE"
  fi

  if [[ -d "$MIGRATION_DIR" ]]; then
    collect_migration_versions() {
      local dir="$1"
      if git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "$PROJECT_ROOT" ls-files -- "$dir"/V*.sql 2>/dev/null \
          | sed -nE 's/.*\/V([0-9]{3})__.*/\1/p'
      else
        find "$dir" -maxdepth 1 -type f -name 'V*.sql' \
          | sed -nE 's/.*\/V([0-9]{3})__.*/\1/p'
      fi
    }

    MAX_MIGRATION_VERSION="$(
      collect_migration_versions "$MIGRATION_DIR" \
      | sort -n \
      | tail -n1
    )"

    if [[ -z "$MAX_MIGRATION_VERSION" ]]; then
      fail "cannot detect max migration version under $MIGRATION_DIR"
    elif ((10#$BASELINE_VERSION_PADDED > 10#$MAX_MIGRATION_VERSION)); then
      fail "baseline version V$BASELINE_VERSION_PADDED is newer than max migration V$MAX_MIGRATION_VERSION"
    elif ((10#$BASELINE_VERSION_PADDED < 10#$MAX_MIGRATION_VERSION)); then
      warn "baseline V$BASELINE_VERSION_PADDED is behind max migration V$MAX_MIGRATION_VERSION (incremental migrations expected)"
    fi
  fi
fi

RUNTIME_VERIFY="${BASELINE_RUNTIME_VERIFY:-false}"
if [[ "$ERRORS" -eq 0 && "$RUNTIME_VERIFY" == "true" ]]; then
  DB_HOST="${DB_HOST:-localhost}"
  DB_PORT="${DB_PORT:-5432}"
  DB_NAME="${DB_NAME:-ljwx_platform}"
  DB_USERNAME="${DB_USERNAME:-postgres}"
  DB_PASSWORD="${DB_PASSWORD:-postgres}"

  if ! command -v psql >/dev/null 2>&1; then
    fail "psql not found (required when BASELINE_RUNTIME_VERIFY=true)"
  else
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -tAc "SELECT 1" >/dev/null 2>&1; then
      fail "cannot connect to PostgreSQL for runtime verify: $DB_HOST:$DB_PORT as $DB_USERNAME"
    else
      info "running runtime baseline verify on $DB_HOST:$DB_PORT/$DB_NAME"
      if ! BASELINE_VERSION="$BASELINE_VERSION" \
        DB_HOST="$DB_HOST" \
        DB_PORT="$DB_PORT" \
        DB_NAME="$DB_NAME" \
        DB_USERNAME="$DB_USERNAME" \
        DB_PASSWORD="$DB_PASSWORD" \
        bash "$RESET_SCRIPT" >/dev/null; then
        fail "reset-database baseline mode failed"
      else
        TABLE_COUNT="$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | xargs || true)"
        if [[ -z "$TABLE_COUNT" ]] || ! [[ "$TABLE_COUNT" =~ ^[0-9]+$ ]]; then
          fail "cannot read table count after baseline import"
        elif ((TABLE_COUNT < 20)); then
          fail "table count too low after baseline import: $TABLE_COUNT"
        fi

        for required_table in sys_user sys_role sys_permission sys_outbox_event msg_subscription; do
          EXISTS_FLAG="$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" -tAc "SELECT to_regclass('public.${required_table}') IS NOT NULL;" 2>/dev/null | xargs || true)"
          if [[ "$EXISTS_FLAG" != "t" ]]; then
            fail "required table missing after baseline import: $required_table"
          fi
        done
      fi
    fi
  fi
elif [[ "$RUNTIME_VERIFY" == "true" ]]; then
  info "runtime verify skipped because static checks already failed"
else
  info "runtime verify skipped (set BASELINE_RUNTIME_VERIFY=true to enable)"
fi

echo "  gate-baseline: ERRORS=$ERRORS WARNINGS=$WARNINGS"
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-baseline: FAILED"
  exit 1
fi
echo "  gate-baseline: PASSED"
exit 0
