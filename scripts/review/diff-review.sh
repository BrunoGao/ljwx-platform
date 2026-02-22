#!/usr/bin/env bash
set -euo pipefail

PHASE_NUM="${1:?Usage: diff-review.sh <phase-number>}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_BRIEF="spec/phase/phase-$(printf '%02d' "$PHASE_NUM").md"
source scripts/lib/parse-phase-brief.sh "$PHASE_BRIEF"

CHANGED_FILES=$(git diff --name-only HEAD)
ERRORS=0
WARNINGS=0

echo "── Diff-driven Review: Phase $PHASE_NUM ($PHASE_TITLE) ──"
echo ""

# ── 1. Scope check ────────────────────────────────────────
echo "[Scope Check]"
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  MATCHED=false
  for pattern in "${PHASE_SCOPE[@]}"; do
    # Direct match
    if [[ "$file" == "$pattern" ]]; then
      MATCHED=true
      break
    fi
    # Trailing /** glob: match any file under the directory
    if [[ "$pattern" == *"/**" ]]; then
      _dir="${pattern%/**}"
      if [[ "$file" == "$_dir/"* ]]; then
        MATCHED=true
        break
      fi
    fi
    # Trailing /* glob: match one level under directory
    if [[ "$pattern" == *"/*" ]] && [[ "$pattern" != *"/**" ]]; then
      _dir="${pattern%/*}"
      _rest="${file#"$_dir/"}"
      if [[ "$file" == "$_dir/"* ]] && [[ "$_rest" != *"/"* ]]; then
        MATCHED=true
        break
      fi
    fi
  done
  if ! $MATCHED; then
    echo "  CRITICAL $file — outside Phase $PHASE_NUM scope"
    echo "           (allowed: ${PHASE_SCOPE[*]})"
    ((ERRORS++)) || true
  fi
done <<< "$CHANGED_FILES"
echo ""

# ── 2. No caret (^) in package.json ───────────────────────
echo "[Rule: no-caret]"
CARET_HITS=$(grep -rn '"\^' --include='package.json' . 2>/dev/null | grep -v 'node_modules' || true)
if [[ -n "$CARET_HITS" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — caret (^) version found; must use tilde (~)"
    ((ERRORS++)) || true
  done <<< "$CARET_HITS"
else
  echo "  OK"
fi
echo ""

# ── 3. No `any` type in TypeScript / Vue ──────────────────
echo "[Rule: no-any-type]"
ANY_HITS=$(grep -rn ': any\|as any' --include='*.ts' --include='*.vue' . 2>/dev/null \
  | grep -v 'node_modules' \
  | grep -v '//.*: any' || true)
if [[ -n "$ANY_HITS" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — TypeScript 'any' type found"
    ((ERRORS++)) || true
  done <<< "$ANY_HITS"
else
  echo "  OK"
fi
echo ""

# ── 4. Env var name must be VITE_APP_BASE_API ─────────────
echo "[Rule: env-var-consistency]"
BAD_ENV=$(grep -rn 'VITE_API_BASE_URL\|VITE_BASE_API\|VITE_APP_API\b' \
  --include='*.ts' --include='*.vue' --include='.env' --include='.env.*' . 2>/dev/null \
  | grep -v 'node_modules' || true)
if [[ -n "$BAD_ENV" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — wrong env var name; must be VITE_APP_BASE_API"
    ((ERRORS++)) || true
  done <<< "$BAD_ENV"
else
  echo "  OK"
fi
echo ""

# ── 5. Flyway: no IF NOT EXISTS ───────────────────────────
echo "[Rule: flyway-no-if-not-exists]"
IF_NOT_HITS=$(grep -rni 'IF NOT EXISTS' --include='*.sql' . 2>/dev/null | grep -v 'node_modules' || true)
if [[ -n "$IF_NOT_HITS" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — Flyway migration must not use IF NOT EXISTS"
    ((ERRORS++)) || true
  done <<< "$IF_NOT_HITS"
else
  echo "  OK"
fi
echo ""

# ── 6. Business tables must have all 7 audit columns ──────
echo "[Rule: audit-columns]"
AUDIT_ERRORS=0
SQL_FILES=$(find . -name '*.sql' -path '*/migration/*' 2>/dev/null | grep -v 'node_modules' || true)
while IFS= read -r sql_file; do
  [[ -z "$sql_file" ]] && continue
  # Find each CREATE TABLE statement name
  while IFS= read -r table; do
    [[ -z "$table" ]] && continue
    # Skip Quartz tables
    _tbl_lower=$(echo "$table" | tr '[:upper:]' '[:lower:]')
    if [[ "$_tbl_lower" == *"qrtz_"* ]]; then
      continue
    fi
    # Extract the table body between the CREATE TABLE and the matching );
    TABLE_BLOCK=$(awk "/CREATE TABLE[[:space:]]+${table}[[:space:]]*\(/{found=1} found{print} found && /\);/{exit}" "$sql_file" || true)
    for col in tenant_id created_by created_time updated_by updated_time deleted version; do
      if ! echo "$TABLE_BLOCK" | grep -qi "[[:space:]]${col}[[:space:]]"; then
        echo "  CRITICAL $sql_file — table '$table' missing audit column: $col"
        ((ERRORS++)) || true
        ((AUDIT_ERRORS++)) || true
      fi
    done
  done < <(grep -oP '(?i)CREATE TABLE\s+\K\S+' "$sql_file" 2>/dev/null || true)
done <<< "$SQL_FILES"
if [[ "$AUDIT_ERRORS" -eq 0 ]]; then
  echo "  OK"
fi
echo ""

# ── 7. DTO must not expose tenant_id ──────────────────────
echo "[Rule: dto-no-tenant-id]"
DTO_HITS=$(grep -rn 'tenantId\|tenant_id' \
  --include='*DTO.java' --include='*Dto.java' \
  --include='*Request.java' --include='*Response.java' \
  . 2>/dev/null | grep -v 'node_modules' || true)
if [[ -n "$DTO_HITS" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — DTO must not expose tenantId"
    ((ERRORS++)) || true
  done <<< "$DTO_HITS"
else
  echo "  OK"
fi
echo ""

# ── 8. Controller methods must have @PreAuthorize ─────────
echo "[Rule: controller-preauthorize]"
CTRL_ERRORS=0
CONTROLLER_FILES=$(find . -name '*Controller.java' 2>/dev/null | grep -v 'node_modules' || true)
while IFS= read -r ctrl; do
  [[ -z "$ctrl" ]] && continue
  while IFS= read -r method_line; do
    [[ -z "$method_line" ]] && continue
    LINE_NUM=$(echo "$method_line" | cut -d: -f1)
    LINE_CONTENT=$(echo "$method_line" | cut -d: -f2-)
    # Skip login and refresh endpoints
    if echo "$LINE_CONTENT" | grep -q 'login\|refresh'; then
      continue
    fi
    START=$((LINE_NUM > 3 ? LINE_NUM - 3 : 1))
    CONTEXT=$(sed -n "${START},${LINE_NUM}p" "$ctrl" 2>/dev/null || true)
    if ! echo "$CONTEXT" | grep -q '@PreAuthorize'; then
      echo "  CRITICAL $ctrl:$LINE_NUM — mapping without @PreAuthorize"
      ((ERRORS++)) || true
      ((CTRL_ERRORS++)) || true
    fi
  done < <(grep -n '@\(Get\|Post\|Put\|Delete\|Patch\)Mapping' "$ctrl" 2>/dev/null || true)
done <<< "$CONTROLLER_FILES"
if [[ "$CTRL_ERRORS" -eq 0 ]]; then
  echo "  OK"
fi
echo ""

# ── 9. No ${latest.version} in POM ───────────────────────
echo "[Rule: no-latest-version]"
POM_HITS=$(grep -rn '\${latest\.version}' --include='pom.xml' . 2>/dev/null | grep -v 'node_modules' || true)
if [[ -n "$POM_HITS" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — \${latest.version} placeholder found in POM"
    ((ERRORS++)) || true
  done <<< "$POM_HITS"
else
  echo "  OK"
fi
echo ""

# ── 10. DAG: data must not import security ────────────────
echo "[Rule: dag-data-no-security]"
DAG_HITS=$(grep -rn 'import com\.ljwx\.platform\.security' \
  ljwx-platform-data/src/ 2>/dev/null || true)
if [[ -n "$DAG_HITS" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — data module imports security (DAG violation)"
    ((ERRORS++)) || true
  done <<< "$DAG_HITS"
else
  echo "  OK"
fi
echo ""

# ── 11. DAG: security must not import data ────────────────
echo "[Rule: dag-security-no-data]"
DAG_HITS2=$(grep -rn 'import com\.ljwx\.platform\.data' \
  ljwx-platform-security/src/ 2>/dev/null || true)
if [[ -n "$DAG_HITS2" ]]; then
  while IFS= read -r hit; do
    echo "  CRITICAL $hit — security module imports data (DAG violation)"
    ((ERRORS++)) || true
  done <<< "$DAG_HITS2"
else
  echo "  OK"
fi
echo ""

# ── Summary ───────────────────────────────────────────────
echo "════════════════════════════════════════"
echo "  ERRORS: $ERRORS | WARNINGS: $WARNINGS"
if [[ "$ERRORS" -gt 0 ]]; then
  echo "  DIFF REVIEW: FAILED"
  exit 1
else
  echo "  DIFF REVIEW: PASSED"
  exit 0
fi
