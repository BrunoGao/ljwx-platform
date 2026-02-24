#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-integration.sh — 集成测试（Testcontainers + PostgreSQL）
#
# 检查项：
#   1. Docker 可用（Testcontainers 前置条件）
#   2. Maven integration-test 通过
#   3. 仅在后端 Phase 且有测试类时执行
#
# 注意：集成测试较慢，在 CI 中可选跑。
#       本地执行时需要 Docker daemon 运行。
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0

# ── Quick check: is this a backend phase? ──
CURRENT_PHASE=$(sed -n 's/^Phase:[[:space:]]*\([0-9][0-9]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -1 || echo "")
TARGET_BACKEND="true"
if [[ -n "$CURRENT_PHASE" ]]; then
  PHASE_BRIEF="spec/phase/phase-$(printf '%02d' "$CURRENT_PHASE").md"
  if [[ -f "$PHASE_BRIEF" ]]; then
    TB=$(sed -n '/^---$/,/^---$/p' "$PHASE_BRIEF" | grep 'backend:' | awk '{print $2}')
    TARGET_BACKEND="${TB:-true}"
  fi
fi

if [[ "$TARGET_BACKEND" != "true" ]]; then
  echo "  gate-integration: Skipped (not a backend phase)"
  exit 0
fi

# ── Check: any test files exist? ──
TEST_COUNT=$(find . -name '*Test.java' -o -name '*IT.java' 2>/dev/null | grep -v 'node_modules' | wc -l)
if [[ "$TEST_COUNT" -eq 0 ]]; then
  echo "  gate-integration: Skipped (no test files found)"
  exit 0
fi

# ── Check: Docker available? ──
if ! docker info > /dev/null 2>&1; then
  echo "  WARN: Docker not available — skipping integration tests"
  echo "  gate-integration: SKIPPED"
  exit 0
fi

# ── Check: docker-compose up for test DB ──
if [[ -f "docker-compose.yml" ]]; then
  echo "[Integration] Ensuring PostgreSQL is running"
  docker compose -f docker-compose.yml up -d 2>&1
  # Wait for DB to be ready
  for i in $(seq 1 30); do
    if docker compose -f docker-compose.yml exec -T postgres pg_isready -U ljwx > /dev/null 2>&1; then
      echo "  PostgreSQL ready"
      break
    fi
    if [[ $i -eq 30 ]]; then
      echo "  WARN: PostgreSQL not ready after 30s, tests may fail"
    fi
    sleep 1
  done
fi

# ── Run tests ──
echo ""
echo "[Integration] mvn verify"
export TESTCONTAINERS_RYUK_DISABLED=true
if mvn verify -f pom.xml -B -Dtestcontainers.ryuk.disabled=true 2>&1; then
  echo "  PASS: Integration tests passed"
else
  echo "  FAIL: Integration tests failed"
  ((ERRORS++))
fi

# ── Summary ──
echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-integration: FAILED"
  exit 1
fi
echo "  gate-integration: PASSED"
exit 0
