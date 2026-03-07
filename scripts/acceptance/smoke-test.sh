#!/usr/bin/env bash
# Smoke test — verifies health endpoint and admin login after deployment.
# Usage: bash scripts/acceptance/smoke-test.sh [base-url]

set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
ADMIN_USERNAME="${SMOKE_TEST_ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${SMOKE_TEST_ADMIN_PASSWORD:-${LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD:-}}"

echo "===== Smoke Test ====="

if [[ -z "${ADMIN_PASSWORD}" ]]; then
  echo "缺少 SMOKE_TEST_ADMIN_PASSWORD 或 LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD，无法执行登录验收。"
  exit 1
fi

# ── Health check ──
echo "[1] Health check"
for i in $(seq 1 30); do
  if curl -sf "$BASE_URL/actuator/health" > /dev/null 2>&1; then
    echo "  OK: health (attempt $i)"
    break
  fi
  if [[ $i -eq 30 ]]; then
    echo "  FAIL: Health check timed out after 60s"
    exit 1
  fi
  sleep 2
done

# ── Login test ──
echo "[2] Login test (admin)"
RESP=$(curl -sf -X POST "$BASE_URL/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\"}" || echo '{}')

CODE=$(echo "$RESP" | grep -o '"code":[0-9]*' | head -1 | cut -d: -f2 || echo "")
if [[ "$CODE" != "200" ]]; then
  echo "  FAIL: Login returned code=${CODE:-unknown}"
  echo "  Response: $RESP"
  exit 1
fi
echo "  OK: admin login succeeded"

echo "===== Smoke Test PASSED ====="
