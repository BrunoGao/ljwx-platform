#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "============================================"
echo " LJWX Platform Preflight Check"
echo " Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "============================================"
echo ""

# ============================================
# 1. 核心文件存在性检查
# ============================================
echo "[1/8] Core Files"

CORE_FILES=(
  "CLAUDE.md"
  "spec.md"
  "spec/INDEX.md"
  "spec/01-constraints.md"
  "spec/02-architecture.md"
  "spec/03-api.md"
  "spec/04-database.md"
  "spec/05-backend-config.md"
  "spec/06-frontend-config.md"
  "spec/07-devops.md"
  "spec/08-output-rules.md"
)

for f in "${CORE_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    # 非空检查
    if [[ -s "$f" ]]; then
      pass "$f exists and non-empty"
    else
      fail "$f exists but is EMPTY"
    fi
  else
    fail "$f MISSING"
  fi
done

# ============================================
# 2. Phase Brief 文件检查（phase-00 ~ phase-19）
# ============================================
echo ""
echo "[2/8] Phase Brief Files"

for i in $(seq -w 0 19); do
  pf="spec/phase/phase-${i}.md"
  if [[ -f "$pf" && -s "$pf" ]]; then
    pass "$pf"
  else
    fail "$pf missing or empty"
  fi
done

# ============================================
# 3. Claude Code 扩展文件
# ============================================
echo ""
echo "[3/8] Claude Code Extensions"

EXTENSION_FILES=(
  ".claude/skills/phase-exec/SKILL.md"
  ".claude/skills/gate-check/SKILL.md"
)

for f in "${EXTENSION_FILES[@]}"; do
  if [[ -f "$f" && -s "$f" ]]; then
    pass "$f"
  else
    fail "$f missing or empty"
  fi
done

# ============================================
# 4. CLAUDE.md 内容完整性
# ============================================
echo ""
echo "[4/8] CLAUDE.md Content Integrity"

check_claude_md() {
  local keyword="$1"
  local label="$2"
  if grep -qi "$keyword" CLAUDE.md; then
    pass "CLAUDE.md contains: $label"
  else
    fail "CLAUDE.md missing: $label"
  fi
}

check_claude_md "Current Phase"         "Current Phase 标记"
check_claude_md "硬规则"                 "硬规则段"
check_claude_md "版本锁定"              "版本锁定段"
check_claude_md "反模式"                 "反模式段"
check_claude_md "Compact 指令"          "Compact 指令"
check_claude_md "DAG 依赖"              "DAG 依赖规则"
check_claude_md "3.5.11"                "Spring Boot 版本"
check_claude_md "22.22.0"               "Node.js 版本"
check_claude_md "10.30.1"               "pnpm 版本"
check_claude_md "~3.5.28"               "Vue 版本（tilde）"
check_claude_md "~7.3.1"                "Vite 版本（tilde）"
check_claude_md "Vue Router.*@5"        "Vue Router 5 约束"
check_claude_md "VITE_APP_BASE_API"     "环境变量名"
check_claude_md "hasAuthority"          "权限注解格式"

# ============================================
# 5. spec/INDEX.md 防漂移规则
# ============================================
echo ""
echo "[5/8] INDEX.md Integrity"

if grep -qi "单一事实源" spec/INDEX.md; then
  pass "INDEX.md contains 单一事实源 rule"
else
  fail "INDEX.md missing 单一事实源 rule"
fi

if grep -qi "防漂移" spec/INDEX.md; then
  pass "INDEX.md contains 防漂移 rules"
else
  fail "INDEX.md missing 防漂移 rules"
fi

# ============================================
# 6. 版本号唯一性（不应在 spec/ 中重复出现硬编码版本）
# ============================================
echo ""
echo "[6/8] Version Single Source of Truth"

# 检查 spec/ 下是否直接硬编码了 Spring Boot 版本号（应引用 CLAUDE.md）
SB_IN_SPEC=$(grep -rn "3\.5\.11" spec/ 2>/dev/null | grep -v "见 CLAUDE" | grep -v "INDEX" || true)
if [[ -z "$SB_IN_SPEC" ]]; then
  pass "Spring Boot version not duplicated in spec/"
else
  warn "Spring Boot version (3.5.11) found in spec/ — should reference CLAUDE.md instead"
  echo "      $SB_IN_SPEC"
fi

# ============================================
# 7. Phase Brief 结构检查（抽查 phase-00）
# ============================================
echo ""
echo "[7/8] Phase Brief Structure (spot check: phase-00)"

PHASE00="spec/phase/phase-00.md"
if [[ -f "$PHASE00" ]]; then
  for section in "读取清单" "任务" "Phase-Local Manifest" "验收条件"; do
    if grep -qi "$section" "$PHASE00"; then
      pass "phase-00 contains section: $section"
    else
      fail "phase-00 missing section: $section"
    fi
  done
else
  fail "phase-00.md not found, cannot check structure"
fi

# ============================================
# 8. Skill/Agent 格式检查
# ============================================
echo ""
echo "[8/8] Skill/Agent Format"

# Skills 应包含 frontmatter
for skill in .claude/skills/*/SKILL.md; do
  [[ ! -f "$skill" ]] && continue
  if head -1 "$skill" | grep -q "^---"; then
    pass "$skill has YAML frontmatter"
  else
    fail "$skill missing YAML frontmatter"
  fi
  if grep -q "description:" "$skill"; then
    pass "$skill has description field"
  else
    fail "$skill missing description field"
  fi
done

# Agents 应包含 frontmatter (如果存在)
if compgen -G ".claude/agents/*.md" > /dev/null; then
  for agent in .claude/agents/*.md; do
    [[ ! -f "$agent" ]] && continue
    if head -1 "$agent" | grep -q "^---"; then
      pass "$agent has YAML frontmatter"
    else
      fail "$agent missing YAML frontmatter"
    fi
  done
fi

# ============================================
# Summary
# ============================================
echo ""
echo "============================================"
echo " PREFLIGHT SUMMARY"
echo "============================================"
echo "  ✅ PASS: $PASS"
echo "  ❌ FAIL: $FAIL"
echo "  ⚠️  WARN: $WARN"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "  🚫 PREFLIGHT FAILED — Fix $FAIL issue(s) before starting Phase 0"
  echo ""
  exit 1
else
  if [[ $WARN -gt 0 ]]; then
    echo "  ✅ PREFLIGHT PASSED (with $WARN warning(s))"
  else
    echo "  ✅ PREFLIGHT PASSED — Ready to start Phase 0"
  fi
  echo ""
  exit 0
fi
