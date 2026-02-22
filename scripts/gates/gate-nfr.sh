#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-nfr.sh — 非功能性要求（Non-Functional Requirements）检查
#
# 检查项：
#   N01. 文件上传限制配置（50 MB）
#   N02. Caffeine 缓存 TTL 配置（10 min）
#   N03. JWT 配置（access 30min, refresh 7d, HS256）
#   N04. 异步日志线程池配置（core=2, max=4, queue=1024）
#   N05. 操作日志截断长度（4096 bytes）
#   N06. 日志字段脱敏配置
#   N07. Quartz 表前缀 QRTZ_
#   N08. toolchain 版本一致性
#   N09. 前端构建产物大小检查
#   N10. Docker 镜像标签锁定
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0
WARNINGS=0

fail() { echo "  CRITICAL  $1"; ((ERRORS++)); }
warn() { echo "  WARNING   $1"; ((WARNINGS++)); }

# ── Helper: grep across all yml/yaml files ──
find_in_config() {
  grep -rPn "$1" --include='*.yml' --include='*.yaml' --include='*.properties' . 2>/dev/null \
    | grep -v 'node_modules' | grep -v 'target/' || true
}

echo "[N01] File upload limit: 50 MB"
# Check spring.servlet.multipart.max-file-size
UPLOAD_CFG=$(find_in_config 'max-file-size|maxFileSize|multipart\.max')
if [[ -n "$UPLOAD_CFG" ]]; then
  if ! echo "$UPLOAD_CFG" | grep -qi '50MB\|50m\|52428800'; then
    warn "N01 file-upload — config found but may not be 50MB: $UPLOAD_CFG"
  else
    echo "  OK: 50MB limit configured"
  fi
else
  # Check if any application.yml exists yet
  if find . -name 'application*.yml' ! -path '*/node_modules/*' | grep -q .; then
    warn "N01 file-upload — no max-file-size configuration found"
  fi
fi

echo "[N02] Caffeine cache TTL: 10 min"
CACHE_CFG=$(find_in_config 'caffeine|cache.*spec|cache.*expire')
if [[ -n "$CACHE_CFG" ]]; then
  if ! echo "$CACHE_CFG" | grep -qP '(expireAfterWrite|expire-after-write)\s*[=:]\s*10m|600'; then
    warn "N02 cache-ttl — caffeine config found but TTL may not be 10min"
  else
    echo "  OK: Caffeine TTL=10min configured"
  fi
fi

echo "[N03] JWT configuration"
JWT_CFG=$(find_in_config 'jwt|access.*token.*expir|refresh.*token.*expir')
if [[ -n "$JWT_CFG" ]]; then
  if ! echo "$JWT_CFG" | grep -qiP '(30|1800)'; then
    warn "N03 jwt — access token expiry may not be 30min"
  fi
  if ! echo "$JWT_CFG" | grep -qiP '(7d|604800|10080)'; then
    warn "N03 jwt — refresh token expiry may not be 7 days"
  fi
fi
# Check for HS256 in Java source
HS256=$(grep -rn 'HS256\|HmacSHA256\|SignatureAlgorithm.HS256' --include='*.java' . 2>/dev/null | grep -v 'node_modules' || true)
if [[ -z "$HS256" ]]; then
  if find . -name '*.java' -path '*security*' | grep -q .; then
    warn "N03 jwt — no HS256 reference found in Java sources"
  fi
fi

echo "[N04] Async log thread pool"
ASYNC_CFG=$(grep -rPn 'core.?pool.?size|max.?pool.?size|queue.?capacity' --include='*.java' --include='*.yml' . 2>/dev/null \
  | grep -v 'node_modules' | grep -vi 'quartz' || true)
if [[ -n "$ASYNC_CFG" ]]; then
  echo "  OK: Async pool configuration found"
  # Detailed check
  if ! echo "$ASYNC_CFG" | grep -qP '(core|corePoolSize)\s*[=:(]\s*2'; then
    warn "N04 async-pool — core pool size may not be 2"
  fi
  if ! echo "$ASYNC_CFG" | grep -qP '(max|maxPoolSize|maximum)\s*[=:(]\s*4'; then
    warn "N04 async-pool — max pool size may not be 4"
  fi
fi

echo "[N05] Operation log truncation: 4096 bytes"
TRUNC=$(grep -rPn '4096|TRUNCATE|truncat' --include='*.java' . 2>/dev/null \
  | grep -v 'node_modules' | grep -i 'log\|oper' || true)
if [[ -n "$TRUNC" ]]; then
  echo "  OK: Log truncation reference found"
fi

echo "[N06] Log field masking"
MASK=$(grep -rPn 'mask|sensitive|password.*\*|token.*\*|secret.*\*' --include='*.java' . 2>/dev/null \
  | grep -v 'node_modules' || true)
if [[ -n "$MASK" ]]; then
  echo "  OK: Field masking references found"
fi

echo "[N07] Quartz table prefix QRTZ_"
QUARTZ_CFG=$(find_in_config 'tablePrefix|table-prefix|QRTZ_')
if [[ -n "$QUARTZ_CFG" ]]; then
  if echo "$QUARTZ_CFG" | grep -q 'QRTZ_'; then
    echo "  OK: Quartz table prefix QRTZ_ configured"
  else
    warn "N07 quartz — table prefix may not be QRTZ_"
  fi
fi

echo "[N08] Toolchain version locks"
# Check Java version
if [[ -f "pom.xml" ]]; then
  JAVA_VER=$(grep -oP '<java.version>\K[^<]+' pom.xml 2>/dev/null || true)
  if [[ -n "$JAVA_VER" && "$JAVA_VER" != "21" ]]; then
    fail "N08 java-version — pom.xml java.version=$JAVA_VER, expected 21"
  fi
fi
# Check Node version
if [[ -f ".nvmrc" ]]; then
  NODE_VER=$(cat .nvmrc | tr -d '[:space:]')
  if [[ "$NODE_VER" != "22.22.0" ]]; then
    fail "N08 node-version — .nvmrc=$NODE_VER, expected 22.22.0"
  else
    echo "  OK: Node 22.22.0"
  fi
fi
# Check pnpm version
if [[ -f "package.json" ]]; then
  PNPM_VER=$(grep -oP '"packageManager"\s*:\s*"pnpm@\K[^"]+' package.json 2>/dev/null || true)
  if [[ -n "$PNPM_VER" && "$PNPM_VER" != "10.30.1" ]]; then
    fail "N08 pnpm-version — packageManager pnpm @$PNPM_VER, expected 10.30.1"
  fi
fi

echo "[N09] Frontend build size"
ADMIN_DIST="ljwx-platform-admin/packages/admin/dist"
if [[ -d "$ADMIN_DIST" ]]; then
  DIST_SIZE=$(du -sm "$ADMIN_DIST" 2>/dev/null | awk '{print $1}')
  if [[ "$DIST_SIZE" -gt 20 ]]; then
    warn "N09 build-size — admin dist is ${DIST_SIZE}MB (threshold: 20MB)"
  else
    echo "  OK: Admin dist ${DIST_SIZE}MB"
  fi
fi

echo "[N10] Docker image tag locked"
if [[ -f "docker-compose.yml" ]]; then
  PG_IMAGE=$(grep -oP 'image:\s*\Kpostgres:\S+' docker-compose.yml 2>/dev/null || true)
  if [[ -n "$PG_IMAGE" ]]; then
    if [[ "$PG_IMAGE" != "postgres:16.12-alpine" ]]; then
      fail "N10 docker-tag — postgres image=$PG_IMAGE, expected postgres:16.12-alpine"
    else
      echo "  OK: postgres:16.12-alpine"
    fi
  fi
  # Check for 'latest' tag anywhere
  LATEST_TAG=$(grep -n ':latest' docker-compose.yml 2>/dev/null || true)
  if [[ -n "$LATEST_TAG" ]]; then
    fail "N10 docker-tag — :latest found in docker-compose.yml: $LATEST_TAG"
  fi
fi

# ── Summary ──
echo ""
echo "════════════════════════════════════════════════════"
echo "  gate-nfr: ERRORS=$ERRORS  WARNINGS=$WARNINGS"
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-nfr: FAILED"
  exit 1
fi
echo "  gate-nfr: PASSED"
exit 0
