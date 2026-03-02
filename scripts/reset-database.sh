#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# reset-database.sh — 重置本地 PostgreSQL 数据库
#
# 用法:
#   bash scripts/reset-database.sh
#   bash scripts/reset-database.sh --mode empty
#   BASELINE_VERSION=52 bash scripts/reset-database.sh
#
# 功能:
#   1. 断开所有数据库连接
#   2. 删除 ljwx_platform 数据库
#   3. 重建 ljwx_platform 数据库
#   4. （默认）导入 baseline SQL
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ljwx_platform}"
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
BASELINE_VERSION_RAW="${BASELINE_VERSION:-52}"
RESET_MODE="${RESET_MODE:-baseline}"
BASELINE_FILE_INPUT="${BASELINE_FILE:-}"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/reset-database.sh [--mode baseline|empty] [--baseline-file /path/to/file.sql]

Options:
  --mode baseline|empty   baseline: recreate DB and import baseline SQL (default)
                          empty: recreate empty DB only
  --baseline-file FILE    baseline SQL file path (used when mode=baseline)
  -h, --help              show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      RESET_MODE="${2:-}"
      shift 2
      ;;
    --baseline-file)
      BASELINE_FILE_INPUT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[FATAL] unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$BASELINE_VERSION_RAW" =~ ^[0-9]+$ ]]; then
  echo "[FATAL] BASELINE_VERSION must be numeric, got: $BASELINE_VERSION_RAW"
  exit 1
fi
if [[ "$RESET_MODE" != "baseline" && "$RESET_MODE" != "empty" ]]; then
  echo "[FATAL] RESET_MODE must be baseline or empty, got: $RESET_MODE"
  exit 1
fi
BASELINE_VERSION_PADDED="$(printf "%03d" "$((10#$BASELINE_VERSION_RAW))")"

if [[ -n "$BASELINE_FILE_INPUT" ]]; then
  BASELINE_FILE="$BASELINE_FILE_INPUT"
else
  BASELINE_FILE="$PROJECT_ROOT/ljwx-platform-app/src/main/resources/db/baseline/V${BASELINE_VERSION_PADDED}__baseline.sql"
fi

echo "════════════════════════════════════════════════════════"
echo "  Resetting PostgreSQL Database"
echo "  Host: $DB_HOST:$DB_PORT"
echo "  Database: $DB_NAME"
echo "  Mode: $RESET_MODE"
echo "════════════════════════════════════════════════════════"
echo ""

# 设置 PGPASSWORD 环境变量以避免密码提示
export PGPASSWORD="$DB_PASSWORD"

echo "Step 1: Terminating existing connections..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
  AND pid <> pg_backend_pid();
" 2>/dev/null || echo "  (No active connections to terminate)"

echo ""
echo "Step 2: Dropping database '$DB_NAME'..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c "
DROP DATABASE IF EXISTS $DB_NAME;
"

echo ""
echo "Step 3: Creating database '$DB_NAME'..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c "
CREATE DATABASE $DB_NAME;
"

if [[ "$RESET_MODE" == "baseline" ]]; then
  echo ""
  echo "Step 4: Importing baseline (V${BASELINE_VERSION_PADDED})..."
  if [[ ! -f "$BASELINE_FILE" ]]; then
    echo "[FATAL] Baseline file not found: $BASELINE_FILE"
    echo "        Generate baseline first: bash scripts/generate-baseline.sh"
    exit 1
  fi
  DB_HOST="$DB_HOST" \
  DB_PORT="$DB_PORT" \
  DB_NAME="$DB_NAME" \
  DB_USERNAME="$DB_USERNAME" \
  DB_PASSWORD="$DB_PASSWORD" \
  BASELINE_VERSION="$BASELINE_VERSION_PADDED" \
  BASELINE_FILE="$BASELINE_FILE" \
  bash "$PROJECT_ROOT/scripts/apply-baseline.sh"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Database reset complete!"
if [[ "$RESET_MODE" == "baseline" ]]; then
  echo "  Start app with local profile: SPRING_PROFILES_ACTIVE=local"
else
  echo "  You created an empty database (no schema/data yet)"
fi
echo "════════════════════════════════════════════════════════"
