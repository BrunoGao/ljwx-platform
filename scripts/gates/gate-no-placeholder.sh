#!/usr/bin/env bash
# gate-no-placeholder.sh — fail on fake-complete implementation markers
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0
ALLOWLIST_FILE="scripts/gates/placeholder-allowlist.txt"
PATTERN='\bTODO\b|\bFIXME\b|占位(响应|数据|实现)|简化实现|实际应(调用|使用|写入|查询|获取)|Implement actual|Encrypt in production|硬编码 AES 密钥|生产环境应从配置中心获取|example\.com/exports'

TARGETS=(
  "ljwx-platform-app/src/main/java"
  "ljwx-platform-core/src/main/java"
  "ljwx-platform-data/src/main/java"
  "ljwx-platform-security/src/main/java"
  "ljwx-platform-web/src/main/java"
  "ljwx-platform-admin/src"
  "ljwx-platform-screen/src"
  "ljwx-platform-mobile/src"
  "packages/shared/src"
)

GLOBS=(
  "--glob=*.java"
  "--glob=*.kt"
  "--glob=*.js"
  "--glob=*.jsx"
  "--glob=*.ts"
  "--glob=*.tsx"
  "--glob=*.vue"
)

if command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL="rg"
elif command -v grep >/dev/null 2>&1; then
  SEARCH_TOOL="grep"
else
  echo "  FAIL: neither rg nor grep is available for gate-no-placeholder.sh" >&2
  exit 1
fi

echo "[Fake Complete] Scanning for fake-complete markers"

if [[ "$SEARCH_TOOL" == "rg" ]]; then
  hits="$(
    rg -n -S \
      "${GLOBS[@]}" \
      --glob '!**/node_modules/**' \
      --glob '!**/target/**' \
      --glob '!**/dist/**' \
      --glob '!**/.pnpm/**' \
      --glob '!**/auto-imports.d.ts' \
      --glob '!**/components.d.ts' \
      "$PATTERN" \
      "${TARGETS[@]}" 2>/dev/null || true
  )"
else
  GREP_PATTERN='(^|[^[:alnum:]_])(TODO|FIXME)([^[:alnum:]_]|$)|占位(响应|数据|实现)|简化实现|实际应(调用|使用|写入|查询|获取)|Implement actual|Encrypt in production|硬编码 AES 密钥|生产环境应从配置中心获取|example\.com/exports'
  hits="$(
    grep -RInE \
      --include='*.java' \
      --include='*.kt' \
      --include='*.js' \
      --include='*.jsx' \
      --include='*.ts' \
      --include='*.tsx' \
      --include='*.vue' \
      --exclude-dir=node_modules \
      --exclude-dir=target \
      --exclude-dir=dist \
      --exclude-dir=.pnpm \
      --exclude=auto-imports.d.ts \
      --exclude=components.d.ts \
      -- "$GREP_PATTERN" \
      "${TARGETS[@]}" 2>/dev/null || true
  )"
fi

if [[ -f "$ALLOWLIST_FILE" ]]; then
  hits="$(printf '%s\n' "$hits" | grep -F -v -f "$ALLOWLIST_FILE" || true)"
fi

if [[ -n "$hits" ]]; then
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    echo "  FAIL: fake-complete marker found — $hit"
    ERRORS=$((ERRORS + 1))
  done <<< "$hits"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "  gate-no-placeholder: ERRORS=$ERRORS"
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-no-placeholder: FAILED"
  exit 1
fi
echo "  gate-no-placeholder: PASSED"
