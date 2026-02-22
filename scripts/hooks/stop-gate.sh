#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# stop-gate.sh — Stop Hook
#
# 每当 Claude 想停止响应时触发。
# 检查当前 Phase 的最低完成标准，未满足则 block 让 Claude 继续。
#
# 设计原则（来自审查修订）：
#   - 所有检查必须在 100ms 内完成
#   - 不跑编译、不跑 pnpm、不跑任何耗时操作
#   - 只做文件存在性检查 + 轻量 grep
#   - 编译/类型检查交给外层 gate 脚本
#   - 必须处理 stop_hook_active 防止无限循环
#
# 通信协议：
#   exit 0 + 无输出                        = 允许停止
#   exit 0 + {"decision":"block","reason":""} = 阻止停止，reason 反馈给 Claude
#
# 关键安全阀：
#   stop_hook_active=true 时必须放行，否则无限循环
# ═══════════════════════════════════════════════════════════
set -euo pipefail

INPUT=$(cat)

# ══════════════════════════════════════════════════════════
# 安全阀：防止无限循环
# 当 Stop Hook 已经 block 过一次后，Claude 再次尝试停止时
# stop_hook_active 会被设为 true。此时必须放行。
# ══════════════════════════════════════════════════════════
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [[ "$STOP_ACTIVE" == "true" ]]; then
  exit 0
fi

# ══════════════════════════════════════════════════════════
# 确定当前 Phase
# ══════════════════════════════════════════════════════════
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
cd "$PROJECT_DIR"

CURRENT_PHASE=$(grep -oP 'Current Phase:\s*\K\d+' CLAUDE.md 2>/dev/null || echo "")

# 无法确定 Phase → 放行（可能在非 Phase 执行模式下）
if [[ -z "$CURRENT_PHASE" ]]; then
  exit 0
fi

PHASE_PADDED=$(printf '%02d' "$CURRENT_PHASE")
PHASE_BRIEF="spec/phase/phase-${PHASE_PADDED}.md"

# Phase Brief 不存在 → 放行
if [[ ! -f "$PHASE_BRIEF" ]]; then
  exit 0
fi

# ══════════════════════════════════════════════════════════
# 收集 block 原因
# ══════════════════════════════════════════════════════════
BLOCK_REASONS=""

add_block() {
  if [[ -n "$BLOCK_REASONS" ]]; then
    BLOCK_REASONS+=" | "
  fi
  BLOCK_REASONS+="$1"
}

# ══════════════════════════════════════════════════════════
# Check 1: PHASE_MANIFEST.txt 有当前 Phase 的段落
# 耗时：< 1ms
# ══════════════════════════════════════════════════════════
if [[ -f "PHASE_MANIFEST.txt" ]]; then
  # 支持多种 marker 格式
  if ! grep -qP "(## PHASE $CURRENT_PHASE\b|## Phase $CURRENT_PHASE\b)" PHASE_MANIFEST.txt 2>/dev/null; then
    add_block "PHASE_MANIFEST.txt missing section for Phase $CURRENT_PHASE. Write it before stopping."
  fi
else
  add_block "PHASE_MANIFEST.txt not found. Create it and write the Phase $CURRENT_PHASE section."
fi

# ══════════════════════════════════════════════════════════
# Check 2: Phase Brief scope 中的具体文件是否都已创建
# 耗时：< 10ms（通常 scope 不超过 20 个条目）
# ══════════════════════════════════════════════════════════
MISSING_FILES=()
SCOPE_BLOCK=$(sed -n '/^scope:/,/^[a-z]/p' "$PHASE_BRIEF" 2>/dev/null | grep '^\s*-' || true)

if [[ -n "$SCOPE_BLOCK" ]]; then
  while IFS= read -r line; do
    # 提取路径
    ENTRY=$(echo "$line" | sed 's/^\s*-\s*//; s/^"//; s/"$//' | xargs)
    [[ -z "$ENTRY" ]] && continue
    # 跳过 glob 模式
    if [[ "$ENTRY" == *"*"* || "$ENTRY" == *"**"* ]]; then
      continue
    fi
    # 检查文件是否存在
    if [[ ! -f "$ENTRY" && ! -d "$ENTRY" ]]; then
      MISSING_FILES+=("$ENTRY")
    fi
  done <<< "$SCOPE_BLOCK"
fi

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  # 最多报告 5 个缺失文件，避免 reason 过长
  SHOW_COUNT=5
  TOTAL=${#MISSING_FILES[@]}
  DISPLAY=("${MISSING_FILES[@]:0:$SHOW_COUNT}")
  MISSING_LIST=$(printf '%s, ' "${DISPLAY[@]}")
  MISSING_LIST="${MISSING_LIST%, }"  # 去尾逗号
  if [[ $TOTAL -gt $SHOW_COUNT ]]; then
    MISSING_LIST+=" ... and $((TOTAL - SHOW_COUNT)) more"
  fi
  add_block "Missing $TOTAL expected files: $MISSING_LIST. Create them before stopping."
fi

# ══════════════════════════════════════════════════════════
# Check 3: 变更文件中的明显违规（秒级 grep）
# 只检查最容易犯的 3 个错误，完整检查交给 gate-rules.sh
# 耗时：< 50ms
# ══════════════════════════════════════════════════════════
CHANGED=$(git diff --name-only HEAD 2>/dev/null || true)
if [[ -n "$CHANGED" ]]; then

  # 3a: package.json 中的 caret
  CARET_FILES=$(echo "$CHANGED" | grep 'package\.json$' || true)
  for f in $CARET_FILES; do
    [[ -f "$f" ]] || continue
    if grep -q '"\^' "$f" 2>/dev/null; then
      add_block "$f contains caret (^) versions. Replace all ^ with ~ before stopping."
      break  # 报告一次即可
    fi
  done

  # 3b: SQL 中的 IF NOT EXISTS
  SQL_FILES=$(echo "$CHANGED" | grep '\.sql$' || true)
  for f in $SQL_FILES; do
    [[ -f "$f" ]] || continue
    if grep -qi 'IF NOT EXISTS' "$f" 2>/dev/null; then
      add_block "$f contains IF NOT EXISTS. Remove it — Flyway handles migration state."
      break
    fi
  done

  # 3c: DTO 中的 tenantId
  DTO_FILES=$(echo "$CHANGED" | grep -P '(DTO|Dto|Request|Response)\.java$' || true)
  for f in $DTO_FILES; do
    [[ -f "$f" ]] || continue
    if grep -q 'tenantId\|tenant_id' "$f" 2>/dev/null | grep -v 'import ' | grep -v '^\s*//' | head -1 > /dev/null 2>&1; then
      if grep 'tenantId\|tenant_id' "$f" 2>/dev/null | grep -v 'import ' | grep -v '^\s*//' | head -1 > /dev/null 2>&1; then
        add_block "$f is a DTO that exposes tenant_id. Remove the tenantId field."
        break
      fi
    fi
  done
fi

# ══════════════════════════════════════════════════════════
# 决定是否阻止停止
# ══════════════════════════════════════════════════════════
if [[ -n "$BLOCK_REASONS" ]]; then
  # 转义 JSON
  ESCAPED=$(echo "$BLOCK_REASONS" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/ /g')
  echo "{\"decision\":\"block\",\"reason\":\"Cannot stop yet: $ESCAPED\"}"
  exit 0
fi

# 全部通过，允许停止
exit 0
