# DevOps

> 版本号见 CLAUDE.md "版本锁定"段。

## 工具链安装策略

| 工具 | 推荐安装方式 | CI 跳过策略 |
|------|-------------|------------|
| JDK 21 | sdkman / actions/setup-java@v4 | 若 `java -version` 满足则跳过 |
| Maven | Maven Wrapper `./mvnw` | 始终使用 wrapper |
| Node.js | fnm / actions/setup-node@v4 | 若 `node -v` 满足则跳过 |
| pnpm | `corepack enable && corepack prepare` | corepack 自动处理 |
| Docker | 系统级 / docker/setup-buildx-action | Testcontainers 必需 |

## Docker Compose

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16.12-alpine
    container_name: ljwx-postgres
    ports:
      - "${DB_PORT:-5432}:5432"
    environment:
      POSTGRES_DB: ${DB_NAME:-ljwx_platform}
      POSTGRES_USER: ${DB_USERNAME:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME:-postgres} -d ${DB_NAME:-ljwx_platform}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

## CI Gate 脚本

### scripts/gates/gate-all.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "===== LJWX Platform CI Gate ====="

echo "[1/6] Manifest Check..."
bash scripts/gates/gate-manifest.sh

echo "[2/6] Backend Compile + Unit Test..."
bash scripts/gates/gate-compile.sh

echo "[3/6] Integration Test (Testcontainers)..."
bash scripts/gates/gate-integration.sh

echo "[4/6] Contract Check (OpenAPI)..."
bash scripts/gates/gate-contract.sh

echo "[5/6] NFR Check..."
bash scripts/gates/gate-nfr.sh

echo "[6/6] Frontend Build..."
pnpm install --frozen-lockfile
pnpm run build:all

echo "===== ALL GATES PASSED ====="
```

### scripts/gates/gate-compile.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
./mvnw clean verify -DskipITs -T1C
```

### scripts/gates/gate-integration.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
./mvnw verify -PIT -Dfailsafe.rerunFailingTestsCount=1
```

### scripts/gates/gate-manifest.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PHASE_FILE="${1:-PHASE_MANIFEST.txt}"

echo "===== Phase-Local Manifest Check ====="

# ---- Phase-local file existence check ----
if [[ -f "$PHASE_FILE" ]]; then
  MISSING=0
  while IFS= read -r file; do
    [[ -z "$file" || "$file" =~ ^# ]] && continue
    if [[ ! -e "$file" ]]; then
      echo "MISSING: $file"
      MISSING=$((MISSING + 1))
    fi
  done < "$PHASE_FILE"

  if [[ $MISSING -gt 0 ]]; then
    echo "FAIL: $MISSING file(s) missing from phase manifest."
    exit 1
  fi
  echo "Phase-local file check: OK"
else
  echo "WARN: No phase manifest file found ($PHASE_FILE). Skipping phase-local check."
fi

# ---- Check for ^ in package.json (repo-wide) ----
CARET_FOUND=$(grep -RIn '"\^' \
  package.json \
  packages/ \
  ljwx-platform-admin/ \
  ljwx-platform-mobile/ \
  ljwx-platform-screen/ \
  2>/dev/null || true)
if [[ -n "$CARET_FOUND" ]]; then
  echo "FAIL: Found caret (^) version specifiers. Use tilde (~) only."
  echo "$CARET_FOUND"
  exit 1
fi
echo "Caret check: OK"

# ---- Check env var consistency (all three frontends) ----
DEPRECATED_VAR=$(grep -RIn 'VITE_API_BASE_URL' \
  ljwx-platform-admin/ \
  ljwx-platform-mobile/ \
  ljwx-platform-screen/ \
  2>/dev/null || true)
if [[ -n "$DEPRECATED_VAR" ]]; then
  echo "FAIL: Found deprecated VITE_API_BASE_URL. Use VITE_APP_BASE_API."
  echo "$DEPRECATED_VAR"
  exit 1
fi
echo "Env var consistency check: OK"

# ---- Check audit fields in SQL migrations (7 columns) ----
AUDIT_COLUMNS="tenant_id created_by created_time updated_by updated_time deleted version"
for sql in ljwx-platform-app/src/main/resources/db/migration/V*.sql; do
  [[ ! -f "$sql" ]] && continue
  if grep -qi "QRTZ_" "$sql"; then continue; fi
  if grep -qi "CREATE TABLE" "$sql"; then
    for col in $AUDIT_COLUMNS; do
      if ! grep -qi "$col" "$sql"; then
        echo "FAIL: $sql has CREATE TABLE but missing audit column: $col"
        exit 1
      fi
    done
  fi
done
echo "Audit field check: OK"

echo "===== Manifest Check PASSED ====="
```

### scripts/gates/gate-contract.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
bash scripts/tools/export-openapi.sh
if [[ ! -f docs/contracts/openapi.json ]]; then
  echo "FAIL: openapi.json not generated"
  exit 1
fi
echo "Contract check PASSED"
```

### scripts/acceptance/smoke-test.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"

echo "===== Smoke Test ====="

# Health check
for i in $(seq 1 30); do
  if curl -sf "$BASE_URL/actuator/health" > /dev/null 2>&1; then
    echo "Health check passed (attempt $i)"
    break
  fi
  if [[ $i -eq 30 ]]; then
    echo "FAIL: Health check timed out"
    exit 1
  fi
  sleep 2
done

# Login test
RESP=$(curl -sf -X POST "$BASE_URL/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"admin\",\"password\":\"${LJWX_BOOTSTRAP_ADMIN_INITIAL_PASSWORD}\"}")

CODE=$(echo "$RESP" | grep -o '"code":[0-9]*' | head -1 | cut -d: -f2)
if [[ "$CODE" != "200" ]]; then
  echo "FAIL: Login returned code $CODE"
  echo "$RESP"
  exit 1
fi

echo "===== Smoke Test PASSED ====="
```
