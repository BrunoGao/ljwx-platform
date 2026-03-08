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
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0
OPENAPI_BASE_URL="${OPENAPI_BASE_URL:-}"
OPENAPI_FILE="${OPENAPI_FILE:-}"
SYNC_OPENAPI_DOCS="${SYNC_OPENAPI_DOCS:-0}"

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

OPENAPI_OUTPUT="target/openapi.json"
mkdir -p "$(dirname "$OPENAPI_OUTPUT")"

echo "[Contract] Generating OpenAPI spec"
if [[ -n "$OPENAPI_FILE" ]]; then
  if [[ -f "$OPENAPI_FILE" && -s "$OPENAPI_FILE" ]]; then
    cp "$OPENAPI_FILE" "$OPENAPI_OUTPUT"
    echo "  OpenAPI spec loaded from $OPENAPI_FILE"
  else
    echo "  FAIL: OPENAPI_FILE not found or empty — $OPENAPI_FILE"
    ERRORS=$((ERRORS + 1))
  fi
elif [[ -n "$OPENAPI_BASE_URL" ]]; then
  if curl -fsS --retry 5 --retry-delay 1 "${OPENAPI_BASE_URL%/}/v3/api-docs" > "$OPENAPI_OUTPUT"; then
    echo "  OpenAPI spec fetched from $OPENAPI_BASE_URL"
  else
    echo "  FAIL: Could not fetch OpenAPI spec from $OPENAPI_BASE_URL"
    ERRORS=$((ERRORS + 1))
  fi
else
  if grep -q 'springdoc-openapi-maven-plugin' pom.xml 2>/dev/null || \
     grep -rq 'springdoc-openapi-maven-plugin' "$APP_DIR/pom.xml" 2>/dev/null; then
    if mvn verify -f pom.xml -B -DskipTests \
         -Dspringdoc.writer-with-order-by-keys=true 2>&1; then
      echo "  OpenAPI spec generated via Maven plugin"
    else
      echo "  WARN: Maven plugin generation failed, trying runtime generation"
    fi
  fi
  
  if [[ ! -s "$OPENAPI_OUTPUT" ]]; then
    echo "  Attempting runtime OpenAPI generation"
    mvn package -f pom.xml -B -DskipTests -q 2>/dev/null
    APP_JAR=$(find "$APP_DIR/target" -name '*.jar' ! -name '*-sources.jar' 2>/dev/null | head -1)

    if [[ -n "$APP_JAR" && -f "$APP_JAR" ]]; then
      java -jar "$APP_JAR" \
        --server.port=18080 \
        --cache.enabled=false \
        --spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration &
      APP_PID=$!

      for i in $(seq 1 60); do
        if curl -sf http://localhost:18080/v3/api-docs > "$OPENAPI_OUTPUT" 2>/dev/null; then
          echo "  OpenAPI spec fetched from running application"
          break
        fi
        sleep 1
      done

      kill "$APP_PID" 2>/dev/null || true
      wait "$APP_PID" 2>/dev/null || true
    fi
  fi
fi

# ── Validate generated spec ──
if [[ ! -f "$OPENAPI_OUTPUT" || ! -s "$OPENAPI_OUTPUT" ]]; then
  echo "  FAIL: Could not generate OpenAPI spec"
  exit 1
fi

echo ""
echo "[Contract] Validating OpenAPI spec"

# Check: valid JSON
if ! python3 -c "import json; json.load(open('$OPENAPI_OUTPUT'))" 2>/dev/null && \
   ! jq empty "$OPENAPI_OUTPUT" 2>/dev/null; then
  echo "  FAIL: $OPENAPI_OUTPUT is not valid JSON"
  ERRORS=$((ERRORS + 1))
fi

MISSING_OPERATION_IDS="$(jq -r '
  .paths
  | to_entries[]
  | .key as $path
  | .value
  | to_entries[]
  | select(.value.operationId == null or .value.operationId == "")
  | "\(.key | ascii_upcase) \($path)"
' "$OPENAPI_OUTPUT" 2>/dev/null || true)"
if [[ -n "$MISSING_OPERATION_IDS" ]]; then
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    echo "  FAIL: Missing operationId for $hit"
    ERRORS=$((ERRORS + 1))
  done <<< "$MISSING_OPERATION_IDS"
fi

# Check: expected API routes from spec/03-api.md
if [[ -f "spec/03-api.md" ]]; then
  echo "[Contract] Cross-checking with spec/03-api.md"
  EXPECTED_ROUTES="$(
    python3 - "spec/03-api.md" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
routes = set()

table_pattern = re.compile(r"\|\s*(GET|POST|PUT|DELETE|PATCH)\s*\|\s*(/api/[^\s|]+)\s*\|", re.IGNORECASE)
inline_pattern = re.compile(r"\b(GET|POST|PUT|DELETE|PATCH)\s+(/api/\S+)", re.IGNORECASE)

for method, path in table_pattern.findall(text):
    routes.add((method.upper(), path))

for method, path in inline_pattern.findall(text):
    routes.add((method.upper(), path.rstrip("`|),.")))

for method, path in sorted(routes):
    print(f"{method}\t{path}")
PY
  )"

  if [[ -n "$EXPECTED_ROUTES" ]]; then
    SPEC_ERRORS=0
    while IFS=$'\t' read -r expected_method expected_path; do
      [[ -z "$expected_method" || -z "$expected_path" ]] && continue

      canonical_expected="$(echo "$expected_path" | sed -E 's/\{[^}]+\}/{param}/g')"
      method_key="$(echo "$expected_method" | tr '[:upper:]' '[:lower:]')"
      matched_path="$(
        jq -r \
          --arg expected_path "$expected_path" \
          --arg canonical_expected "$canonical_expected" \
          --arg method "$method_key" '
            if .paths[$expected_path] != null then
              $expected_path
            else
              (
                [
                  .paths
                  | to_entries[]
                  | select((.key | gsub("\\{[^}]+\\}"; "{param}")) == $canonical_expected and .value[$method] != null)
                  | .key
                ][0]
              ) // (
                [
                  .paths
                  | keys[]
                  | select((gsub("\\{[^}]+\\}"; "{param}")) == $canonical_expected)
                ][0]
              ) // ""
            end
          ' "$OPENAPI_OUTPUT" 2>/dev/null
      )"

      if [[ -z "$matched_path" ]]; then
        echo "  FAIL: Expected route $expected_method $expected_path not found in generated spec"
        SPEC_ERRORS=$((SPEC_ERRORS + 1))
        continue
      fi

      if ! jq -e --arg path "$matched_path" --arg method "$method_key" '.paths[$path][$method] != null' "$OPENAPI_OUTPUT" >/dev/null 2>&1; then
        actual_methods="$(jq -r --arg path "$matched_path" '.paths[$path] | keys | map(ascii_upcase) | join(", ")' "$OPENAPI_OUTPUT" 2>/dev/null || true)"
        echo "  FAIL: Expected route $expected_method $expected_path not exported (available methods: ${actual_methods:-none})"
        SPEC_ERRORS=$((SPEC_ERRORS + 1))
      fi
    done <<< "$EXPECTED_ROUTES"

    if [[ $SPEC_ERRORS -gt 0 ]]; then
      echo "  FAIL: $SPEC_ERRORS spec routes not satisfied by generated OpenAPI"
      ERRORS=$((ERRORS + SPEC_ERRORS))
    else
      echo "  PASS: All expected API routes found"
    fi
  fi
fi

if [[ -f "docs/api/openapi.json" ]]; then
  ACTUAL_PATHS_FILE="$(mktemp)"
  REPO_PATHS_FILE="$(mktemp)"
  jq -r '.paths | keys[]' "$OPENAPI_OUTPUT" | sort -u >"$ACTUAL_PATHS_FILE"
  jq -r '.paths | keys[]' "docs/api/openapi.json" | sort -u >"$REPO_PATHS_FILE"

  RUNTIME_ONLY="$(comm -23 "$ACTUAL_PATHS_FILE" "$REPO_PATHS_FILE" || true)"
  REPO_ONLY="$(comm -13 "$ACTUAL_PATHS_FILE" "$REPO_PATHS_FILE" || true)"

  if [[ -n "$RUNTIME_ONLY" || -n "$REPO_ONLY" ]]; then
    echo "[Contract] Checking docs/api/openapi.json drift"
    if [[ -n "$RUNTIME_ONLY" ]]; then
      while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        echo "  FAIL: runtime-only path missing from docs/api/openapi.json — $path"
        ERRORS=$((ERRORS + 1))
      done <<< "$RUNTIME_ONLY"
    fi
    if [[ -n "$REPO_ONLY" ]]; then
      while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        echo "  FAIL: stale docs/api/openapi.json path not exported at runtime — $path"
        ERRORS=$((ERRORS + 1))
      done <<< "$REPO_ONLY"
    fi
  fi
fi

if [[ "$SYNC_OPENAPI_DOCS" == "1" ]]; then
  mkdir -p docs/api
  cp "$OPENAPI_OUTPUT" docs/api/openapi.json
  echo "  Synced docs/api/openapi.json from generated spec"
fi

# ── Summary ──
echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-contract: FAILED"
  exit 1
fi
echo "  gate-contract: PASSED"
exit 0
