#!/usr/bin/env bash
# gate-flyway-governance.sh — enforce immutable Flyway history after apply
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

LOCK_FILE="scripts/gates/flyway-checksums.lock"
MIG_DIR="ljwx-platform-app/src/main/resources/db/migration"
ERRORS=0
WARNINGS=0

fail() { echo "  CRITICAL  $1"; ((ERRORS++)); }
warn() { echo "  WARNING   $1"; ((WARNINGS++)); }

if [[ ! -d "$MIG_DIR" ]]; then
  echo "[SKIP] migration directory not found: $MIG_DIR"
  exit 0
fi

if [[ ! -f "$LOCK_FILE" ]]; then
  fail "flyway-lock missing: $LOCK_FILE"
  echo "  create lock file by: find $MIG_DIR -maxdepth 1 -type f -name 'V*.sql' | sort | xargs sha256sum > $LOCK_FILE"
  exit 1
fi

echo "[R13] Flyway migration immutability"

# Track locked files and maximum locked version.
MAX_LOCKED=0
while read -r SUM FILE; do
  [[ -z "${SUM:-}" || -z "${FILE:-}" ]] && continue
  if [[ ! -f "$FILE" ]]; then
    fail "flyway-lock file missing on disk: $FILE"
    continue
  fi
  CURRENT_SUM="$(sha256sum "$FILE" | awk '{print $1}')"
  if [[ "$CURRENT_SUM" != "$SUM" ]]; then
    fail "flyway-lock checksum mismatch: $FILE"
  fi

  BASE="$(basename "$FILE")"
  VER_RAW="$(echo "$BASE" | sed -nE 's/^V([0-9]{3})__.*/\1/p')"
  if [[ -n "$VER_RAW" ]]; then
    VER_NUM=$((10#$VER_RAW))
    if (( VER_NUM > MAX_LOCKED )); then
      MAX_LOCKED=$VER_NUM
    fi
  fi
done < "$LOCK_FILE"

# Ensure no migration <= MAX_LOCKED escapes lock file.
while IFS= read -r FILE; do
  BASE="$(basename "$FILE")"
  VER_RAW="$(echo "$BASE" | sed -nE 's/^V([0-9]{3})__.*/\1/p')"
  [[ -z "$VER_RAW" ]] && continue
  VER_NUM=$((10#$VER_RAW))

  if (( VER_NUM <= MAX_LOCKED )); then
    if ! grep -qE "[[:space:]]${FILE}\$" "$LOCK_FILE"; then
      fail "flyway-lock missing entry for existing migration: $FILE"
    fi
  else
    warn "new migration detected (append to lock after review): $FILE"
  fi
done < <(find "$MIG_DIR" -maxdepth 1 -type f -name 'V*.sql' | sort)

echo "  gate-flyway-governance: ERRORS=$ERRORS WARNINGS=$WARNINGS"
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-flyway-governance: FAILED"
  exit 1
fi

echo "  gate-flyway-governance: PASSED"
exit 0
