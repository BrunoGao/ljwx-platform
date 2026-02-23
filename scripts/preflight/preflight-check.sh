#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# preflight-check.sh — LJWX Platform 全量自检
#
# 在开始代码生成前运行，验证：
#   Section A: 文件存在性（55 个基础设施文件）
#   Section B: 文件非空性
#   Section C: CLAUDE.md 关键内容
#   Section D: spec/01-constraints.md 单一事实源
#   Section E: Phase Brief 结构完整性
#   Section F: settings.json 权限配置
#   Section G: Agent / Skill 定义完整性
#   Section H: 脚本可执行性
#   Section I: 版本号一致性
#   Section J: 跨文件引用一致性
#   Section K: 工具链环境检查
#
# 输出：PASS / FAIL / WARN 计数
# 退出：有 FAIL 则非零退出
# ═══════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PASS=0
FAIL=0
WARN=0

pass() { echo "  PASS  $1"; ((PASS++)); }
fail() { echo "  FAIL  $1"; ((FAIL++)); }
warn() { echo "  WARN  $1"; ((WARN++)); }

# ══════════════════════════════════════════════════════════
# Section A: 文件存在性
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section A: File Existence                       ║"
echo "╚══════════════════════════════════════════════════╝"

# ── A1: 根目录文件 ──
ROOT_FILES=(
  "CLAUDE.md"
  "spec.md"
)
for f in "${ROOT_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    pass "A1 $f exists"
  else
    fail "A1 $f MISSING"
  fi
done

# PHASE_MANIFEST.txt 可能在 Phase 0 之后才创建
if [[ -f "PHASE_MANIFEST.txt" ]]; then
  pass "A1 PHASE_MANIFEST.txt exists"
else
  warn "A1 PHASE_MANIFEST.txt not yet created (will be created during Phase 0)"
fi

# ── A2: spec/ 主文件 ──
SPEC_FILES=(
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
for f in "${SPEC_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    pass "A2 $f exists"
  else
    fail "A2 $f MISSING"
  fi
done

# ── A3: Phase Brief 文件 ──
for i in $(seq 0 19); do
  PADDED=$(printf '%02d' "$i")
  BRIEF="spec/phase/phase-${PADDED}.md"
  if [[ -f "$BRIEF" ]]; then
    pass "A3 $BRIEF exists"
  else
    fail "A3 $BRIEF MISSING"
  fi
done

# ── A4: .claude/ 配置 ──
CLAUDE_FILES=(
  ".claude/settings.json"
  ".claude/agents/backend-builder.md"
  ".claude/agents/frontend-builder.md"
  ".claude/agents/code-reviewer.md"
  ".claude/skills/phase-exec/SKILL.md"
  ".claude/skills/gate-check/SKILL.md"
  ".claude/skills/preflight/SKILL.md"
)
for f in "${CLAUDE_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    pass "A4 $f exists"
  else
    fail "A4 $f MISSING"
  fi
done

# ── A5: scripts/ ──
SCRIPT_FILES=(
  "scripts/gates/gate-all.sh"
  "scripts/gates/gate-manifest.sh"
  "scripts/gates/gate-rules.sh"
  "scripts/gates/gate-compile.sh"
  "scripts/gates/gate-integration.sh"
  "scripts/gates/gate-contract.sh"
  "scripts/gates/gate-nfr.sh"
  "scripts/hooks/pre-edit-guard.sh"
  "scripts/hooks/post-edit-check.sh"
  "scripts/hooks/stop-gate.sh"
  "scripts/review/diff-review.sh"
  "scripts/lib/parse-phase-brief.sh"
  "scripts/preflight/preflight-check.sh"
  "scripts/phase-execute.sh"
  "scripts/phase-parallel.sh"
  "scripts/run-all.sh"
)
for f in "${SCRIPT_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    pass "A5 $f exists"
  else
    fail "A5 $f MISSING"
  fi
done

echo ""

# ══════════════════════════════════════════════════════════
# Section B: 文件非空性（只检查已存在的文件）
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section B: Files Non-Empty                      ║"
echo "╚══════════════════════════════════════════════════╝"

ALL_FILES=(
  "${ROOT_FILES[@]}"
  "${SPEC_FILES[@]}"
  "${CLAUDE_FILES[@]}"
  "${SCRIPT_FILES[@]}"
)
for f in "${ALL_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    if [[ -s "$f" ]]; then
      pass "B $f non-empty ($(wc -l < "$f") lines)"
    else
      fail "B $f EXISTS but EMPTY"
    fi
  fi
done

# Phase Brief 非空检查
for i in $(seq 0 19); do
  PADDED=$(printf '%02d' "$i")
  BRIEF="spec/phase/phase-${PADDED}.md"
  if [[ -f "$BRIEF" ]]; then
    if [[ -s "$BRIEF" ]]; then
      pass "B $BRIEF non-empty"
    else
      fail "B $BRIEF EXISTS but EMPTY"
    fi
  fi
done

echo ""

# ══════════════════════════════════════════════════════════
# Section C: CLAUDE.md 关键内容
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section C: CLAUDE.md Content                    ║"
echo "╚══════════════════════════════════════════════════╝"

if [[ -f "CLAUDE.md" ]]; then
  CLAUDE_CONTENT=$(cat CLAUDE.md)

  KEYWORDS=(
    "Current Phase"
    "DAG"
    "core"
    "security"
    "data"
    "web"
    "app"
    "audit"
    "tenant_id"
    "@PreAuthorize"
    "VITE_APP_BASE_API"
    "Vue Router"
    "IF NOT EXISTS"
    "BCrypt"
    "~"
  )
  for kw in "${KEYWORDS[@]}"; do
    if echo "$CLAUDE_CONTENT" | grep -qi "$kw"; then
      pass "C CLAUDE.md contains '$kw'"
    else
      fail "C CLAUDE.md MISSING keyword: '$kw'"
    fi
  done

  # 检查 CLAUDE.md 行数（应 < 300 行）
  LINE_COUNT=$(wc -l < CLAUDE.md)
  if [[ $LINE_COUNT -le 300 ]]; then
    pass "C CLAUDE.md size: $LINE_COUNT lines (within 300 limit)"
  else
    warn "C CLAUDE.md has $LINE_COUNT lines (exceeds 300 recommendation)"
  fi

  # 检查版本锁定表存在
  if echo "$CLAUDE_CONTENT" | grep -q 'Spring Boot'; then
    pass "C CLAUDE.md contains backend version reference"
  else
    fail "C CLAUDE.md MISSING backend version lock table"
  fi

  if echo "$CLAUDE_CONTENT" | grep -q 'Vue.*3\.5'; then
    pass "C CLAUDE.md contains frontend version reference"
  else
    fail "C CLAUDE.md MISSING frontend version lock table"
  fi
else
  fail "C CLAUDE.md not found (skipping content checks)"
fi

echo ""

# ══════════════════════════════════════════════════════════
# Section D: spec/01-constraints.md 单一事实源
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section D: Constraints Single Source of Truth   ║"
echo "╚══════════════════════════════════════════════════╝"

CONSTRAINTS="spec/01-constraints.md"
if [[ -f "$CONSTRAINTS" ]]; then
  CONSTRAINT_CONTENT=$(cat "$CONSTRAINTS")

  CONSTRAINT_KEYS=(
    "tenant_id"
    "created_by"
    "created_time"
    "updated_by"
    "updated_time"
    "deleted"
    "version"
    "HS256"
    "30.*min|1800"
    "7.*day|604800"
    "QRTZ_"
    "4096"
    "50.*MB|52428800"
    "caffeine"
    "strict: true"
  )
  for kw in "${CONSTRAINT_KEYS[@]}"; do
    if echo "$CONSTRAINT_CONTENT" | grep -qiE "$kw"; then
      pass "D constraints contains: $kw"
    else
      fail "D constraints MISSING: $kw"
    fi
  done

  # 检查版本号是否在 constraints 中定义
  VERSION_KEYS=(
    "Java.*21"
    "Spring Boot.*3\.5"
    "MyBatis.*3\.0"
    "PostgreSQL.*16"
    "Node.*22"
    "pnpm.*10"
    "Vue.*3\.5"
    "Vite.*7\.3"
    "TypeScript.*5\.9"
    "Element Plus.*2\.13"
  )
  for vk in "${VERSION_KEYS[@]}"; do
    if echo "$CONSTRAINT_CONTENT" | grep -qE "$vk"; then
      pass "D version defined: $vk"
    else
      warn "D version not found in constraints: $vk"
    fi
  done
else
  fail "D $CONSTRAINTS not found (skipping)"
fi

echo ""

# ══════════════════════════════════════════════════════════
# Section E: Phase Brief 结构完整性
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section E: Phase Brief Structure                ║"
echo "╚══════════════════════════════════════════════════╝"

for i in $(seq 0 19); do
  PADDED=$(printf '%02d' "$i")
  BRIEF="spec/phase/phase-${PADDED}.md"

  if [[ ! -f "$BRIEF" ]]; then
    continue  # Already reported in Section A
  fi

  # E1: YAML front-matter 存在
  if ! head -1 "$BRIEF" | grep -q '^---$'; then
    fail "E1 $BRIEF missing YAML front-matter (first line must be ---)"
    continue
  fi

  FRONT_MATTER=$(sed -n '/^---$/,/^---$/p' "$BRIEF" | sed '1d;$d')

  # E2: 必需字段
  REQUIRED_FIELDS=("phase:" "title:" "targets:" "scope:")
  for field in "${REQUIRED_FIELDS[@]}"; do
    if echo "$FRONT_MATTER" | grep -q "$field"; then
      pass "E2 $BRIEF has field: $field"
    else
      fail "E2 $BRIEF MISSING field: $field"
    fi
  done

  # E3: targets 有 backend 和 frontend 布尔值
  if echo "$FRONT_MATTER" | grep -qE 'backend:[[:space:]]*(true|false)'; then
    pass "E3 $BRIEF targets.backend is boolean"
  else
    fail "E3 $BRIEF targets.backend must be true or false"
  fi
  if echo "$FRONT_MATTER" | grep -qE 'frontend:[[:space:]]*(true|false)'; then
    pass "E3 $BRIEF targets.frontend is boolean"
  else
    fail "E3 $BRIEF targets.frontend must be true or false"
  fi

  # E4: phase 编号与文件名匹配
  PHASE_VAL=$(echo "$FRONT_MATTER" | grep '^phase:' | awk '{print $2}')
  if [[ "$PHASE_VAL" == "$i" ]]; then
    pass "E4 $BRIEF phase number matches filename ($i)"
  else
    fail "E4 $BRIEF phase=$PHASE_VAL but filename says $i"
  fi

  # E5: scope 至少有一个条目
  SCOPE_COUNT=$(echo "$FRONT_MATTER" | sed -n '/^scope:/,/^[a-z]/p' | grep '^\s*-' | wc -l)
  if [[ $SCOPE_COUNT -gt 0 ]]; then
    pass "E5 $BRIEF scope has $SCOPE_COUNT entries"
  else
    fail "E5 $BRIEF scope is empty (must list at least one file)"
  fi

  # E6: Brief 文件不超过 400 行
  BRIEF_LINES=$(wc -l < "$BRIEF")
  if [[ $BRIEF_LINES -le 400 ]]; then
    pass "E6 $BRIEF is $BRIEF_LINES lines (within 400 limit)"
  else
    warn "E6 $BRIEF has $BRIEF_LINES lines (exceeds 400 recommendation)"
  fi
done

echo ""

# ══════════════════════════════════════════════════════════
# Section F: settings.json 权限配置
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section F: Settings Configuration               ║"
echo "╚══════════════════════════════════════════════════╝"

SETTINGS=".claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  # F1: 有效 JSON
  if jq empty "$SETTINGS" 2>/dev/null; then
    pass "F1 $SETTINGS is valid JSON"
  else
    fail "F1 $SETTINGS is NOT valid JSON"
  fi

  # F2: defaultMode 存在且为 dontAsk
  MODE=$(jq -r '.permissions.defaultMode // empty' "$SETTINGS" 2>/dev/null)
  if [[ "$MODE" == "dontAsk" ]]; then
    pass "F2 defaultMode = dontAsk"
  elif [[ -n "$MODE" ]]; then
    warn "F2 defaultMode = $MODE (expected dontAsk)"
  else
    fail "F2 defaultMode not set"
  fi

  # F3: deny 列表包含危险命令
  DENY_LIST=$(jq -r '.permissions.deny[]? // empty' "$SETTINGS" 2>/dev/null)
  REQUIRED_DENY=(
    "git push"
    "rm -rf"
    "curl"
    "wget"
    "sudo"
  )
  for rd in "${REQUIRED_DENY[@]}"; do
    if echo "$DENY_LIST" | grep -q "$rd"; then
      pass "F3 deny contains: $rd"
    else
      fail "F3 deny MISSING: $rd"
    fi
  done

  # F4: 不包含过宽的 allow 规则
  ALLOW_LIST=$(jq -r '.permissions.allow[]? // empty' "$SETTINGS" 2>/dev/null)
  DANGEROUS_ALLOWS=(
    'Bash(\* --help)'
    'Bash(\* --version)'
    'Bash(\*)'
  )
  for da in "${DANGEROUS_ALLOWS[@]}"; do
    if echo "$ALLOW_LIST" | grep -qF "$da"; then
      fail "F4 allow has over-broad rule: $da"
    else
      pass "F4 allow does not contain: $da"
    fi
  done

  # F5: 敏感文件在 deny 中
  SENSITIVE_DENY=(
    ".env"
    ".ssh"
    ".pem"
    ".key"
  )
  for sd in "${SENSITIVE_DENY[@]}"; do
    if echo "$DENY_LIST" | grep -q "$sd"; then
      pass "F5 deny protects: $sd"
    else
      warn "F5 deny does not explicitly protect: $sd"
    fi
  done

  # F6: hooks 配置存在 (SessionStart is not a Claude Code hook type — skip)
  HOOK_EVENTS=("PreToolUse" "PostToolUse" "Stop")
  for event in "${HOOK_EVENTS[@]}"; do
    if jq -e ".hooks.${event}" "$SETTINGS" > /dev/null 2>&1; then
      pass "F6 hook configured: $event"
    else
      fail "F6 hook MISSING: $event"
    fi
  done

  # F7: sandbox 配置
  SANDBOX_ENABLED=$(jq -r '.sandbox.enabled // false' "$SETTINGS" 2>/dev/null)
  if [[ "$SANDBOX_ENABLED" == "true" ]]; then
    pass "F7 sandbox enabled"
  else
    warn "F7 sandbox not enabled"
  fi

  AUTO_ALLOW=$(jq -r '.sandbox.autoAllowBashIfSandboxed // "not set"' "$SETTINGS" 2>/dev/null)
  if [[ "$AUTO_ALLOW" == "false" ]]; then
    pass "F7 autoAllowBashIfSandboxed = false"
  elif [[ "$AUTO_ALLOW" == "true" ]]; then
    fail "F7 autoAllowBashIfSandboxed = true (should be false to enforce whitelist)"
  else
    warn "F7 autoAllowBashIfSandboxed not explicitly set"
  fi

  # F8: agent team 环境变量
  TEAM_FLAG=$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // empty' "$SETTINGS" 2>/dev/null)
  if [[ "$TEAM_FLAG" == "1" ]]; then
    pass "F8 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = 1"
  else
    warn "F8 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS not set to 1"
  fi

  # F9: Task 权限
  ALLOWED_AGENTS=("Task(backend-builder)" "Task(frontend-builder)" "Task(code-reviewer)")
  for agent in "${ALLOWED_AGENTS[@]}"; do
    if echo "$ALLOW_LIST" | grep -qF "$agent"; then
      pass "F9 allow contains: $agent"
    else
      fail "F9 allow MISSING: $agent"
    fi
  done

  # F10: WebFetch 和 WebSearch 在 deny 中
  for tool in "WebSearch" "WebFetch"; do
    if echo "$DENY_LIST" | grep -q "$tool"; then
      pass "F10 deny contains: $tool"
    else
      warn "F10 deny does not contain: $tool"
    fi
  done
else
  fail "F $SETTINGS not found (skipping)"
fi

echo ""

# ══════════════════════════════════════════════════════════
# Section G: Agent / Skill 定义完整性
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section G: Agent & Skill Definitions            ║"
echo "╚══════════════════════════════════════════════════╝"

# G1: Agent 文件有 YAML front-matter
AGENT_FILES=(
  ".claude/agents/backend-builder.md"
  ".claude/agents/frontend-builder.md"
  ".claude/agents/code-reviewer.md"
)
for af in "${AGENT_FILES[@]}"; do
  if [[ ! -f "$af" ]]; then
    continue
  fi
  if head -1 "$af" | grep -q '^---$'; then
    pass "G1 $af has YAML front-matter"
  else
    fail "G1 $af MISSING YAML front-matter"
  fi

  # G2: 必需的 front-matter 字段
  FM=$(sed -n '/^---$/,/^---$/p' "$af" | sed '1d;$d')
  for field in "name:" "description:" "model:" "permissionMode:"; do
    if echo "$FM" | grep -q "$field"; then
      pass "G2 $af has: $field"
    else
      fail "G2 $af MISSING: $field"
    fi
  done

  # G3: code-reviewer 必须是 plan 模式（只读）
  if [[ "$af" == *"code-reviewer"* ]]; then
    PM=$(echo "$FM" | grep 'permissionMode:' | awk '{print $2}')
    if [[ "$PM" == "plan" ]]; then
      pass "G3 code-reviewer is plan mode (read-only)"
    else
      fail "G3 code-reviewer permissionMode=$PM (must be plan)"
    fi
  fi
done

# G4: Skill 文件有 YAML front-matter
SKILL_FILES=(
  ".claude/skills/phase-exec/SKILL.md"
  ".claude/skills/gate-check/SKILL.md"
  ".claude/skills/preflight/SKILL.md"
)
for sf in "${SKILL_FILES[@]}"; do
  if [[ ! -f "$sf" ]]; then
    continue
  fi
  if head -1 "$sf" | grep -q '^---$'; then
    pass "G4 $sf has YAML front-matter"
  else
    fail "G4 $sf MISSING YAML front-matter"
  fi

  FM=$(sed -n '/^---$/,/^---$/p' "$sf" | sed '1d;$d')
  for field in "name:" "description:"; do
    if echo "$FM" | grep -q "$field"; then
      pass "G4 $sf has: $field"
    else
      fail "G4 $sf MISSING: $field"
    fi
  done
done

echo ""

# ══════════════════════════════════════════════════════════
# Section H: 脚本可执行性 + Shebang
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section H: Script Executability                 ║"
echo "╚══════════════════════════════════════════════════╝"

ALL_SCRIPTS=(
  "scripts/gates/gate-all.sh"
  "scripts/gates/gate-manifest.sh"
  "scripts/gates/gate-rules.sh"
  "scripts/gates/gate-compile.sh"
  "scripts/gates/gate-integration.sh"
  "scripts/gates/gate-contract.sh"
  "scripts/gates/gate-nfr.sh"
  "scripts/hooks/pre-edit-guard.sh"
  "scripts/hooks/post-edit-check.sh"
  "scripts/hooks/stop-gate.sh"
  "scripts/review/diff-review.sh"
  "scripts/lib/parse-phase-brief.sh"
  "scripts/preflight/preflight-check.sh"
  "scripts/phase-execute.sh"
  "scripts/phase-parallel.sh"
  "scripts/run-all.sh"
)

for script in "${ALL_SCRIPTS[@]}"; do
  if [[ ! -f "$script" ]]; then
    continue
  fi

  # H1: 有 shebang
  FIRST_LINE=$(head -1 "$script")
  if [[ "$FIRST_LINE" == "#!/"* ]]; then
    pass "H1 $script has shebang"
  else
    fail "H1 $script MISSING shebang (first line: $FIRST_LINE)"
  fi

  # H2: 有 set -euo pipefail 或 set -uo pipefail
  if grep -q 'set -[eu]*o pipefail' "$script"; then
    pass "H2 $script has strict mode (set -euo pipefail)"
  else
    warn "H2 $script missing strict mode"
  fi

  # H3: 文件有可执行权限（或在 git 中标记为可执行）
  if [[ -x "$script" ]]; then
    pass "H3 $script is executable"
  else
    warn "H3 $script not executable (run: chmod +x $script)"
  fi
done

echo ""

# ══════════════════════════════════════════════════════════
# Section I: 版本号一致性
# 检查版本号是否只在 01-constraints.md 中定义一次
# 其他文件引用时不能定义不同的值
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section I: Version Consistency                  ║"
echo "╚══════════════════════════════════════════════════╝"

if [[ -f "spec/01-constraints.md" ]]; then
  # 从 constraints 提取版本号
  declare -A VERSIONS
  VERSIONS=(
    ["spring_boot"]="$(sed -n 's/.*Spring Boot[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' spec/01-constraints.md 2>/dev/null | head -1)"
    ["vue"]="$(sed -n 's/.*Vue[^0-9]*~*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' spec/01-constraints.md 2>/dev/null | head -1)"
    ["vite"]="$(sed -n 's/.*Vite[^0-9]*~*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' spec/01-constraints.md 2>/dev/null | head -1)"
    ["typescript"]="$(sed -n 's/.*TypeScript[^0-9]*~*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' spec/01-constraints.md 2>/dev/null | head -1)"
    ["node"]="$(sed -n 's/.*Node[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' spec/01-constraints.md 2>/dev/null | head -1)"
    ["pnpm"]="$(sed -n 's/.*pnpm[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' spec/01-constraints.md 2>/dev/null | head -1)"
    ["postgres"]="$(sed -n 's/.*PostgreSQL[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' spec/01-constraints.md 2>/dev/null | head -1)"
  )

  for name in "${!VERSIONS[@]}"; do
    ver="${VERSIONS[$name]}"
    if [[ -n "$ver" ]]; then
      pass "I $name version defined: $ver"
    else
      warn "I $name version not found in constraints"
    fi
  done

  # 交叉检查 CLAUDE.md 中引用的版本是否一致
  if [[ -f "CLAUDE.md" ]]; then
    for name in "${!VERSIONS[@]}"; do
      ver="${VERSIONS[$name]}"
      [[ -z "$ver" ]] && continue

      case "$name" in
        "spring_boot")
          CLAUDE_VER=$(sed -n 's/.*Spring Boot[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -1)
          ;;
        "vue")
          CLAUDE_VER=$(sed -n 's/.*Vue[^0-9]*~*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -1)
          ;;
        "node")
          CLAUDE_VER=$(sed -n 's/.*Node[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -1)
          ;;
        *)
          CLAUDE_VER=""
          ;;
      esac

      if [[ -n "$CLAUDE_VER" ]]; then
        if [[ "$CLAUDE_VER" == "$ver" ]]; then
          pass "I $name version consistent: constraints=$ver CLAUDE.md=$CLAUDE_VER"
        else
          fail "I $name version MISMATCH: constraints=$ver CLAUDE.md=$CLAUDE_VER"
        fi
      fi
    done
  fi

  # 检查是否有其他 spec 文件重复定义版本号
  for spec_file in spec/02-architecture.md spec/05-backend-config.md spec/06-frontend-config.md spec/07-devops.md; do
    if [[ ! -f "$spec_file" ]]; then
      continue
    fi
    for name in "${!VERSIONS[@]}"; do
      ver="${VERSIONS[$name]}"
      [[ -z "$ver" ]] && continue
      # 查找该版本号是否出现在其他 spec 文件中（排除引用性质的提及）
      HITS=$(grep -c "$ver" "$spec_file" 2>/dev/null || echo "0")
      if [[ "$HITS" -gt 0 ]]; then
        warn "I $spec_file mentions version $ver ($name) — ensure it's a reference, not a redefinition"
      fi
    done
  done
else
  warn "I spec/01-constraints.md not found — skipping version consistency"
fi

echo ""

# ══════════════════════════════════════════════════════════
# Section J: 跨文件引用一致性
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section J: Cross-Reference Consistency          ║"
echo "╚══════════════════════════════════════════════════╝"

# J1: settings.json 中引用的 hook 脚本都存在
if [[ -f ".claude/settings.json" ]]; then
  HOOK_COMMANDS=$(jq -r '.. | .command? // empty' .claude/settings.json 2>/dev/null | grep 'scripts/' || true)
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    # 提取脚本路径（替换 $CLAUDE_PROJECT_DIR 为 .）
    SCRIPT_PATH=$(echo "$cmd" | sed 's/.*bash //; s/ .*//' | sed 's|\$CLAUDE_PROJECT_DIR/||')
    if [[ -f "$SCRIPT_PATH" ]]; then
      pass "J1 Hook references existing script: $SCRIPT_PATH"
    else
      fail "J1 Hook references MISSING script: $SCRIPT_PATH (from command: $cmd)"
    fi
  done <<< "$HOOK_COMMANDS"
fi

# J2: spec.md stub 引用 CLAUDE.md 和 spec/INDEX.md
if [[ -f "spec.md" ]]; then
  if grep -q 'CLAUDE.md' spec.md; then
    pass "J2 spec.md references CLAUDE.md"
  else
    warn "J2 spec.md does not reference CLAUDE.md"
  fi
  if grep -q 'spec/INDEX.md\|spec/' spec.md; then
    pass "J2 spec.md references spec/"
  else
    warn "J2 spec.md does not reference spec/"
  fi
fi

# J3: INDEX.md 列出了所有 spec 文件
if [[ -f "spec/INDEX.md" ]]; then
  for sf in "${SPEC_FILES[@]}"; do
    BASENAME=$(basename "$sf")
    [[ "$BASENAME" == "INDEX.md" ]] && continue  # index doesn't list itself
    if grep -q "$BASENAME" spec/INDEX.md; then
      pass "J3 INDEX.md lists: $BASENAME"
    else
      fail "J3 INDEX.md MISSING: $BASENAME"
    fi
  done
fi

# J4: Phase Brief 中 depends_on 引用的 Phase 编号合法
for i in $(seq 0 19); do
  PADDED=$(printf '%02d' "$i")
  BRIEF="spec/phase/phase-${PADDED}.md"
  [[ ! -f "$BRIEF" ]] && continue

  DEPS=$(sed -n '/^---$/,/^---$/p' "$BRIEF" | grep 'depends_on:' | sed 's/depends_on:\s*\[//; s/\]//; s/,/ /g' | xargs 2>/dev/null || true)
  for dep in $DEPS; do
    if [[ "$dep" =~ ^[0-9]+$ && "$dep" -ge 0 && "$dep" -le 19 && "$dep" -lt "$i" ]]; then
      pass "J4 $BRIEF depends_on $dep (valid)"
    elif [[ "$dep" =~ ^[0-9]+$ ]]; then
      if [[ "$dep" -ge "$i" ]]; then
        fail "J4 $BRIEF depends_on $dep (forward dependency — Phase $i cannot depend on Phase $dep)"
      else
        fail "J4 $BRIEF depends_on $dep (invalid Phase number)"
      fi
    fi
  done
done

echo ""

# ══════════════════════════════════════════════════════════
# Section K: 工具链环境检查
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║  Section K: Toolchain Environment                ║"
echo "╚══════════════════════════════════════════════════╝"

# K1: jq 可用（hooks 和 settings 解析需要）
if command -v jq > /dev/null 2>&1; then
  JQ_VER=$(jq --version 2>&1)
  pass "K1 jq available: $JQ_VER"
else
  fail "K1 jq NOT FOUND — required by hooks and preflight"
fi

# K2: git 可用
if command -v git > /dev/null 2>&1; then
  GIT_VER=$(git --version)
  pass "K2 git available: $GIT_VER"

  # K2a: git worktree 支持
  if git worktree list > /dev/null 2>&1; then
    pass "K2 git worktree supported"
  else
    warn "K2 git worktree not supported (needed for parallel execution)"
  fi
else
  fail "K2 git NOT FOUND"
fi

# K3: Claude Code CLI 可用
if command -v claude > /dev/null 2>&1; then
  CLAUDE_VER=$(claude --version 2>&1 || echo "unknown")
  pass "K3 Claude Code CLI available: $CLAUDE_VER"
else
  fail "K3 Claude Code CLI NOT FOUND — required for code generation"
fi

# K4: Java (可选 — 如果还没到后端 Phase)
if command -v java > /dev/null 2>&1; then
  JAVA_VER=$(java -version 2>&1 | head -1)
  pass "K4 Java available: $JAVA_VER"
  if echo "$JAVA_VER" | grep -q '21'; then
    pass "K4 Java version matches (21)"
  else
    warn "K4 Java version may not be 21: $JAVA_VER"
  fi
else
  warn "K4 Java NOT FOUND (needed for backend phases)"
fi

# K5: Maven wrapper 或 mvn
if [[ -f "mvnw" ]]; then
  pass "K5 Maven wrapper (mvnw) exists"
elif command -v mvn > /dev/null 2>&1; then
  MVN_VER=$(mvn --version 2>&1 | head -1)
  pass "K5 Maven available: $MVN_VER"
else
  warn "K5 Maven NOT FOUND (needed for backend phases)"
fi

# K6: Node.js
if command -v node > /dev/null 2>&1; then
  NODE_VER=$(node --version 2>&1)
  pass "K6 Node available: $NODE_VER"
  if [[ "$NODE_VER" == *"22."* ]]; then
    pass "K6 Node version matches (v22.x)"
  else
    warn "K6 Node version expected v22.x, got: $NODE_VER"
  fi
else
  warn "K6 Node NOT FOUND (needed for frontend phases)"
fi

# K7: pnpm
if command -v pnpm > /dev/null 2>&1; then
  PNPM_VER=$(pnpm --version 2>&1)
  pass "K7 pnpm available: $PNPM_VER"
else
  warn "K7 pnpm NOT FOUND (needed for frontend phases)"
fi

# K8: Docker
if command -v docker > /dev/null 2>&1; then
  if docker info > /dev/null 2>&1; then
    pass "K8 Docker available and running"
  else
    warn "K8 Docker installed but daemon not running"
  fi
else
  warn "K8 Docker NOT FOUND (needed for integration tests)"
fi

# K9: grep -P (Perl regex) 支持
if echo "test" | grep -P 'test' > /dev/null 2>&1; then
  pass "K9 grep -P (PCRE) supported"
else
  # Check if any gate/hook scripts still use grep -P (they should not on macOS)
  PCRE_HITS=$(grep -rlF 'grep -P' scripts/gates/ scripts/hooks/ 2>/dev/null | tr '\n' ' ' || true)
  if [[ -n "$PCRE_HITS" ]]; then
    fail "K9 grep -P not supported, but scripts still use PCRE: $PCRE_HITS"
  else
    pass "K9 grep -P not available, but all scripts use ERE (macOS compatible)"
  fi
fi

# K10: sed 基本功能
if echo "test123" | sed 's/[0-9]//g' | grep -q 'test'; then
  pass "K10 sed available and functional"
else
  fail "K10 sed not functional"
fi

echo ""

# ══════════════════════════════════════════════════════════
# 总结
# ══════════════════════════════════════════════════════════
echo "╔══════════════════════════════════════════════════╗"
echo "║                 PREFLIGHT SUMMARY                ║"
echo "╠══════════════════════════════════════════════════╣"
printf "║  PASS: %-5d                                    ║\n" "$PASS"
printf "║  FAIL: %-5d                                    ║\n" "$FAIL"
printf "║  WARN: %-5d                                    ║\n" "$WARN"
TOTAL=$((PASS + FAIL + WARN))
printf "║  TOTAL: %-4d                                    ║\n" "$TOTAL"
echo "╠══════════════════════════════════════════════════╣"

if [[ $FAIL -eq 0 ]]; then
  echo "║                                                  ║"
  echo "║   PREFLIGHT: PASSED                              ║"
  echo "║   Ready to execute: /phase-exec 0                ║"
  echo "║                                                  ║"
  echo "╚══════════════════════════════════════════════════╝"
  exit 0
else
  echo "║                                                  ║"
  echo "║   PREFLIGHT: FAILED                              ║"
  echo "║   Fix $FAIL failure(s) above before proceeding.   ║"
  echo "║                                                  ║"
  echo "╚══════════════════════════════════════════════════╝"
  exit 1
fi
