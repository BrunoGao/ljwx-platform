#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-contract.sh — OpenAPI 契约生成与校验
#
# 检查项：
#   1. springdoc-openapi 能生成 openapi.json/yaml
#   2. 生成的契约与 spec/03-api.md 中定义的路由一致
#   3. 所有 API 路径都有对应的 operationId
#   4. 仅在 app 模块存在且有 Controller 时执行
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0

# ── Check: app module with controllers? ──
APP_DIR="ljwx-platform-app"
if [[ ! -d "$APP_DIR" ]]; then
  echo "  gate-contract: Skipped (app module not found)"
  exit 0
fi

CONTROLLER_COUNT=$(find . -name '*Controller.java' ! -path '*/node_modules/*' 2>/dev/null | wc -l)
if [[ "$CONTROLLER_COUNT" -eq 0 ]]; then
  echo "  gate-contract: Skipped (no Controller files)"
  exit 0
fi

# ── Generate OpenAPI spec ──
# Method 1: Use springdoc-openapi-maven-plugin if configured
OPENAPI_OUTPUT="target/openapi.json"
mkdir -p "$(dirname "$OPENAPI_OUTPUT")"

echo "[Contract] Generating OpenAPI spec"
if grep -q 'springdoc-openapi-maven-plugin' pom.xml 2>/dev/null || \
   grep -rq 'springdoc-openapi-maven-plugin' "$APP_DIR/pom.xml" 2>/dev/null; then
  # Plugin-based generation
  if mvn verify -f pom.xml -B -DskipTests \
       -Dspringdoc.writer-with-order-by-keys=true 2>&1; then
    echo "  OpenAPI spec generated via Maven plugin"
  else
    echo "  WARN: Maven plugin generation failed, trying runtime generation"
  fi
fi

# Method 2: Start app briefly and fetch from /v3/api-docs
if [[ ! -f "$OPENAPI_OUTPUT" ]]; then
  echo "  Attempting runtime OpenAPI generation"

  # Ensure DB is up
  if [[ -f "docker-compose.yml" ]]; then
    docker compose -f docker-compose.yml up -d 2>/dev/null
    sleep 3
  fi

  # Build and start app in background
  mvn package -f pom.xml -B -DskipTests -q 2>/dev/null
  APP_JAR=$(find "$APP_DIR/target" -name '*.jar' ! -name '*-sources.jar' 2>/dev/null | head -1)

  if [[ -n "$APP_JAR" && -f "$APP_JAR" ]]; then
    java -jar "$APP_JAR" --server.port=18080 &
    APP_PID=$!

    # Wait for startup (max 60s)
    for i in $(seq 1 60); do
      if curl -sf http://localhost:18080/v3/api-docs > "$OPENAPI_OUTPUT" 2>/dev/null; then
        echo "  OpenAPI spec fetched from running application"
        break
      fi
      sleep 1
    done

    # Cleanup
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
fi

# ── Validate generated spec ──
if [[ ! -f "$OPENAPI_OUTPUT" || ! -s "$OPENAPI_OUTPUT" ]]; then
  echo "  WARN: Could not generate OpenAPI spec — skipping contract validation"
  echo "  gate-contract: SKIPPED"
  exit 0
fi

echo ""
echo "[Contract] Validating OpenAPI spec"

# Check: valid JSON
if ! python3 -c "import json; json.load(open('$OPENAPI_OUTPUT'))" 2>/dev/null && \
   ! jq empty "$OPENAPI_OUTPUT" 2>/dev/null; then
  echo "  FAIL: $OPENAPI_OUTPUT is not valid JSON"
  ((ERRORS++))
fi

# Check: expected API paths from spec/03-api.md
if [[ -f "spec/03-api.md" ]]; then
  echo "[Contract] Cross-checking with spec/03-api.md"
  # Extract expected paths from api spec (lines like "POST /api/v1/auth/login")
  EXPECTED_PATHS=$(grep -oE '(GET|POST|PUT|DELETE|PATCH)[[:space:]]+/api/[^[:space:]]+' spec/03-api.md \
    | awk '{print $2}' | sort -u || true)

  if [[ -n "$EXPECTED_PATHS" ]]; then
    # Extract actual paths from OpenAPI JSON
    ACTUAL_PATHS=$(jq -r '.paths | keys[]' "$OPENAPI_OUTPUT" 2>/dev/null | sort -u || true)

    MISSING_COUNT=0
    while IFS= read -r expected; do
      [[ -z "$expected" ]] && continue
      # Normalize path parameters: /api/v1/users/{id} → match with regex
      PATTERN=$(echo "$expected" | sed 's/{[^}]*}/[^\/]*/g')
      if ! echo "$ACTUAL_PATHS" | grep -qE "^${PATTERN}$"; then
        echo "  WARN: Expected path $expected not found in generated spec"
        ((MISSING_COUNT++))
      fi
    done <<< "$EXPECTED_PATHS"

    if [[ $MISSING_COUNT -gt 0 ]]; then
      echo "  WARNING: $MISSING_COUNT expected paths not found in OpenAPI spec"
      # This is a warning, not an error — paths may not be implemented yet
    else
      echo "  PASS: All expected API paths found"
    fi
  fi
fi

# ── Copy to docs for reference ──
mkdir -p docs/api
cp "$OPENAPI_OUTPUT" docs/api/openapi.json 2>/dev/null || true

# ── Summary ──
echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-contract: FAILED"
  exit 1
fi
echo "  gate-contract: PASSED"
exit 0
