#!/usr/bin/env bash
# Smoke test — verifies health endpoint and admin login after deployment.
# Usage: bash scripts/acceptance/smoke-test.sh [base-url]

set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"

echo "===== Smoke Test ====="

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
  -d '{"username":"admin","password":"Admin@12345"}' || echo '{}')

CODE=$(echo "$RESP" | grep -o '"code":[0-9]*' | head -1 | cut -d: -f2 || echo "")
if [[ "$CODE" != "200" ]]; then
  echo "  FAIL: Login returned code=${CODE:-unknown}"
  echo "  Response: $RESP"
  exit 1
fi
echo "  OK: admin login succeeded"

echo "===== Smoke Test PASSED ====="
