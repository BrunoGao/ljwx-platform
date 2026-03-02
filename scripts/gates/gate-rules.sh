#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# gate-rules.sh — 硬规则全仓扫描
#
# 这是最终裁决层，覆盖所有 Hook 无法完全检查的规则。
# 与 diff-review.sh（增量扫描）不同，gate-rules 扫描全仓。
#
# 检查项：
#   R01. 无 caret (^) 在任何 package.json
#   R02. 无 TypeScript 'any' 类型
#   R03. 环境变量只用 VITE_APP_BASE_API
#   R04. Flyway 无 IF NOT EXISTS
#   R05. 业务表有 7 审计列（Quartz 表除外）
#   R06. DTO 不暴露 tenant_id
#   R07. Controller 方法有 @PreAuthorize
#   R08. POM 无 ${latest.version}
#   R09. 依赖版本无 ^ (pom.xml 中的 SNAPSHOT 除外)
#   R10. DAG 违规检查（import 方向）
#   R11. Vue Router v5 API（无已废弃的 v4 用法）
#   R12. BCrypt cost factor = 10
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

ERRORS=0
WARNINGS=0

fail() { echo "  CRITICAL  $1"; ((ERRORS++)); }
warn() { echo "  WARNING   $1"; ((WARNINGS++)); }

echo "[R01] No caret (^) in package.json"
CARET_HITS=$(grep -rn '"\^' --include='package.json' . 2>/dev/null | grep -v 'node_modules' || true)
if [[ -n "$CARET_HITS" ]]; then
  while IFS= read -r hit; do
    fail "R01 no-caret — $hit"
  done <<< "$CARET_HITS"
fi

echo "[R02] No TypeScript 'any' type"
# Match ': any', 'as any', '<any>' but exclude comments and node_modules
# Use grep -En (ERE) for macOS BSD grep compatibility
ANY_HITS=$(grep -rEn '(:\s*any[^a-zA-Z]|as any[^a-zA-Z]|<any>)' --include='*.ts' --include='*.vue' . 2>/dev/null \
  | grep -v 'node_modules' \
  | grep -v '\.d\.ts:' \
  | grep -v '// eslint-disable' \
  | grep -v '// @ts-' || true)
if [[ -n "$ANY_HITS" ]]; then
  while IFS= read -r hit; do
    fail "R02 no-any — $hit"
  done <<< "$ANY_HITS"
fi

echo "[R03] Env var must be VITE_APP_BASE_API only"
BAD_ENV=$(grep -rEn 'VITE_API_BASE_URL|VITE_BASE_API' \
  --include='*.ts' --include='*.vue' --include='.env' --include='.env.*' . 2>/dev/null \
  | grep -v 'node_modules' || true)
if [[ -n "$BAD_ENV" ]]; then
  while IFS= read -r hit; do
    fail "R03 env-var — $hit — must use VITE_APP_BASE_API"
  done <<< "$BAD_ENV"
fi

echo "[R04] Flyway: no IF NOT EXISTS"
IFNE_HITS=$(grep -rEni 'IF[[:space:]]+NOT[[:space:]]+EXISTS' --include='*.sql' . 2>/dev/null | grep -v 'node_modules' || true)
if [[ -n "$IFNE_HITS" ]]; then
  while IFS= read -r hit; do
    fail "R04 flyway-no-ifne — $hit"
  done <<< "$IFNE_HITS"
fi

echo "[R05] Audit columns in business tables"
SQL_FILES=$(find . -name '*.sql' -path '*/migration/*' ! -path '*/node_modules/*' ! -path '*/target/*' 2>/dev/null || true)
AUDIT_COLS=(tenant_id created_by created_time updated_by updated_time deleted version)
for sql_file in $SQL_FILES; do
  # Extract CREATE TABLE names using ERE (macOS compatible)
  while IFS= read -r table_name; do
    [[ -z "$table_name" ]] && continue
    # Skip Quartz tables
    TABLE_LOWER=$(echo "$table_name" | tr '[:upper:]' '[:lower:]')
    if [[ "$TABLE_LOWER" == *"qrtz_"* ]]; then
      continue
    fi
    # Get the table definition block
    TABLE_BLOCK=$(sed -n "/CREATE TABLE.*${table_name}/I,/);/p" "$sql_file")
    # Skip PostgreSQL partition tables (PARTITION OF syntax)
    if echo "$TABLE_BLOCK" | grep -qi 'PARTITION[[:space:]]\+OF'; then
      continue
    fi
    for col in "${AUDIT_COLS[@]}"; do
      if [[ -z "$(echo "$TABLE_BLOCK" | grep -i "$col")" ]]; then
        fail "R05 audit-col — $sql_file table $table_name missing column: $col"
      fi
    done
  done < <(grep -oEi 'CREATE[[:space:]]+TABLE[[:space:]]+([`"]?)([A-Za-z_][A-Za-z0-9_]*)' "$sql_file" 2>/dev/null \
    | sed -E 's/CREATE[[:space:]]+TABLE[[:space:]]+[`"]*//i' || true)
done

echo "[R06] DTO must not expose tenant_id"
DTO_HITS=$(grep -rEn '(private|protected|public)[[:space:]]+[^[:space:]]+[[:space:]]+tenantId' \
  --include='*DTO.java' --include='*Dto.java' \
  --include='*Request.java' --include='*Response.java' . 2>/dev/null \
  | grep -v 'node_modules' || true)
if [[ -n "$DTO_HITS" ]]; then
  while IFS= read -r hit; do
    fail "R06 dto-no-tenant — $hit"
  done <<< "$DTO_HITS"
fi
# Also check record-style DTOs / constructor params
DTO_RECORD_HITS=$(grep -rEn 'tenantId' \
  --include='*DTO.java' --include='*Dto.java' \
  --include='*Request.java' --include='*Response.java' . 2>/dev/null \
  | grep -v 'node_modules' \
  | grep -v 'import ' \
  | grep -v '//' || true)
if [[ -n "$DTO_RECORD_HITS" ]]; then
  while IFS= read -r hit; do
    # Avoid double-counting field declarations already caught above
    if [[ -z "$(echo "$hit" | grep -E '(private|protected|public)[[:space:]]+[^[:space:]]+[[:space:]]+tenantId')" ]]; then
      fail "R06 dto-no-tenant (record/param) — $hit"
    fi
  done <<< "$DTO_RECORD_HITS"
fi

echo "[R07] Controller @PreAuthorize"
CONTROLLER_FILES=$(find . -name '*Controller.java' ! -path '*/node_modules/*' 2>/dev/null || true)
for ctrl in $CONTROLLER_FILES; do
  MAPPING_LINES=$(grep -En '@(Get|Post|Put|Delete|Patch)Mapping' "$ctrl" 2>/dev/null | cut -d: -f1 || true)
  for LINE_NUM in $MAPPING_LINES; do
    START=$((LINE_NUM - 5))
    [[ $START -lt 1 ]] && START=1
    CONTEXT=$(sed -n "${START},${LINE_NUM}p" "$ctrl")
    if [[ -z "$(echo "$CONTEXT" | grep '@PreAuthorize')" ]]; then
      fail "R07 preauthorize — $ctrl:$LINE_NUM @*Mapping without @PreAuthorize"
    fi
  done
done

echo "[R08] POM: no \${latest.version}"
POM_HITS=$(grep -rn '\${latest.version}' --include='pom.xml' . 2>/dev/null || true)
if [[ -n "$POM_HITS" ]]; then
  while IFS= read -r hit; do
    fail "R08 no-latest — $hit"
  done <<< "$POM_HITS"
fi

echo "[R09] POM: no SNAPSHOT in release dependencies"
SNAP_HITS=$(grep -rEn '<version>[^<]*SNAPSHOT[^<]*</version>' --include='pom.xml' . 2>/dev/null \
  | grep -v 'project version' || true)
if [[ -n "$SNAP_HITS" ]]; then
  while IFS= read -r hit; do
    warn "R09 no-snapshot — $hit"
  done <<< "$SNAP_HITS"
fi

echo "[R10] DAG: module import direction"
# security must not import from web
SEC_WEB=$(grep -rn 'import.*ljwx.*web\.' --include='*.java' ./ljwx-platform-security/ 2>/dev/null || true)
if [[ -n "$SEC_WEB" ]]; then
  while IFS= read -r hit; do
    fail "R10 dag — security→web violation: $hit"
  done <<< "$SEC_WEB"
fi
# data must not import from security or web
DATA_SEC=$(grep -rn 'import.*ljwx.*security\.' --include='*.java' ./ljwx-platform-data/ 2>/dev/null || true)
DATA_WEB=$(grep -rn 'import.*ljwx.*web\.' --include='*.java' ./ljwx-platform-data/ 2>/dev/null || true)
if [[ -n "$DATA_SEC" ]]; then
  while IFS= read -r hit; do
    fail "R10 dag — data→security violation: $hit"
  done <<< "$DATA_SEC"
fi
if [[ -n "$DATA_WEB" ]]; then
  while IFS= read -r hit; do
    fail "R10 dag — data→web violation: $hit"
  done <<< "$DATA_WEB"
fi
# core must not import from security, data, or web
for MOD in security data web; do
  CORE_HITS=$(grep -rn "import.*ljwx.*${MOD}\." --include='*.java' ./ljwx-platform-core/ 2>/dev/null || true)
  if [[ -n "$CORE_HITS" ]]; then
    while IFS= read -r hit; do
      fail "R10 dag — core→$MOD violation: $hit"
    done <<< "$CORE_HITS"
  fi
done

echo "[R11] Vue Router v5 API compliance"
# Check for deprecated v4 patterns
V4_PATTERNS=(
  'onBeforeRouteLeave'
  'onBeforeRouteUpdate'
  'useLink'
  'RouterLink.*:to.*v-slot'
)
for pattern in "${V4_PATTERNS[@]}"; do
  V4_HITS=$(grep -rEn "$pattern" --include='*.vue' --include='*.ts' . 2>/dev/null | grep -v 'node_modules' || true)
  if [[ -n "$V4_HITS" ]]; then
    while IFS= read -r hit; do
      warn "R11 vue-router-v5 — possible v4 API usage: $hit"
    done <<< "$V4_HITS"
  fi
done

echo "[R12] BCrypt cost factor"
BCRYPT_HITS=$(grep -rEn 'BCryptPasswordEncoder[[:space:]]*\(' --include='*.java' . 2>/dev/null || true)
if [[ -n "$BCRYPT_HITS" ]]; then
  while IFS= read -r hit; do
    # If explicit numeric arg and NOT 10, fail
    if [[ -n "$(echo "$hit" | grep -E 'BCryptPasswordEncoder[[:space:]]*\([[:space:]]*[0-9]')" ]]; then
      if [[ -z "$(echo "$hit" | grep -E 'BCryptPasswordEncoder[[:space:]]*\([[:space:]]*10[[:space:]]*\)')" ]]; then
        fail "R12 bcrypt-cost — $hit — must use cost factor 10"
      fi
    fi
    # Default constructor BCryptPasswordEncoder() is acceptable (defaults to 10)
  done <<< "$BCRYPT_HITS"
fi

# ── Summary ──
echo ""
echo "════════════════════════════════════════════════════"
echo "  gate-rules: ERRORS=$ERRORS  WARNINGS=$WARNINGS"
if [[ $ERRORS -gt 0 ]]; then
  echo "  gate-rules: FAILED"
  exit 1
fi
echo "  gate-rules: PASSED"
exit 0
