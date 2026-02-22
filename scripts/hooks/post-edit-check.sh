#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# post-edit-check.sh — PostToolUse Hook for Edit|Write
#
# 在 Claude 成功写入/修改文件之后触发。
# 读取磁盘上的实际文件内容进行规则检查（不依赖 tool_input 内容字段）。
#
# 检查规则：
#   P01. package.json 无 caret (^)
#   P02. DTO/Request/Response 不暴露 tenantId
#   P03. TypeScript 无 'any' 类型
#   P04. Controller 方法有 @PreAuthorize
#   P05. SQL 迁移无 IF NOT EXISTS
#   P06. 前端只用 VITE_APP_BASE_API
#   P07. POM 无 ${latest.version} 占位符
#   P08. 业务表 SQL 有审计列（轻量检查）
#   P09. Java import 不违反 DAG
#   P10. Vue Router v5 API（无已废弃 v4 模式）
#
# 通信协议：
#   exit 0 + 无输出        = 通过
#   exit 0 + JSON stdout   = {"decision":"block","reason":"..."} 反馈给 Claude 修正
#   （PostToolUse 无法撤销已写入的内容，但 block 会让 Claude 立即修复）
# ═══════════════════════════════════════════════════════════
set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# 拿不到路径或文件不存在，放行
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi
FILE_PATH="${FILE_PATH#./}"
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# 收集所有问题
ISSUES=""

add_issue() {
  if [[ -n "$ISSUES" ]]; then
    ISSUES+=" | "
  fi
  ISSUES+="$1"
}

# ══════════════════════════════════════════════════════════
# P01: package.json 无 caret (^)
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" == *"package.json"* ]]; then
  CARET_LINES=$(grep -n '"\^' "$FILE_PATH" 2>/dev/null || true)
  if [[ -n "$CARET_LINES" ]]; then
    FIRST_LINE=$(echo "$CARET_LINES" | head -1)
    add_issue "[P01] $FILE_PATH has caret (^) version — must use tilde (~). First occurrence: $FIRST_LINE"
  fi
fi

# ══════════════════════════════════════════════════════════
# P02: DTO/Request/Response 不暴露 tenantId
# 覆盖 class 字段声明、record 参数、方法参数
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ (DTO|Dto|Request|Response|Req|Resp|Vo|VO)\.java$ ]]; then
  # 排除 import 行和注释行
  TENANT_HITS=$(grep -n 'tenantId\|tenant_id' "$FILE_PATH" 2>/dev/null \
    | grep -v '^\s*//' \
    | grep -v '^.*import ' || true)
  if [[ -n "$TENANT_HITS" ]]; then
    FIRST_HIT=$(echo "$TENANT_HITS" | head -1)
    add_issue "[P02] $FILE_PATH exposes tenant_id — DTOs must not contain tenantId. Line: $FIRST_HIT"
  fi
fi

# ══════════════════════════════════════════════════════════
# P03: TypeScript 无 'any' 类型
# 匹配 ': any', 'as any', '<any>', 排除注释和类型声明文件
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ \.(ts|vue)$ && ! "$FILE_PATH" =~ \.d\.ts$ ]]; then
  # 搜索 any 用法，排除注释行
  ANY_LINES=$(grep -Pn '(?<!//.*)(\:\s*any\b|as\s+any\b|<any>)' "$FILE_PATH" 2>/dev/null \
    | grep -v '^\s*//' \
    | grep -v '// eslint-disable' \
    | grep -v '// @ts-' || true)
  if [[ -n "$ANY_LINES" ]]; then
    FIRST_ANY=$(echo "$ANY_LINES" | head -1)
    COUNT=$(echo "$ANY_LINES" | wc -l)
    add_issue "[P03] $FILE_PATH has TypeScript 'any' type ($COUNT occurrences). First: $FIRST_ANY. Use proper types."
  fi
fi

# ══════════════════════════════════════════════════════════
# P04: Controller 方法有 @PreAuthorize
# 在 @*Mapping 注解上方 5 行内必须有 @PreAuthorize
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ Controller\.java$ ]]; then
  MAPPING_LINES=$(grep -n ' @(Get|Post|Put|Delete|Patch)Mapping' "$FILE_PATH" 2>/dev/null \
    | cut -d: -f1 || true)
  MISSING_AUTH=""
  for LINE_NUM in $MAPPING_LINES; do
    [[ -z "$LINE_NUM" ]] && continue
    START=$((LINE_NUM - 5))
    [[ $START -lt 1 ]] && START=1
    CONTEXT=$(sed -n "${START},${LINE_NUM}p" "$FILE_PATH")
    if ! echo "$CONTEXT" | grep -q ' @PreAuthorize'; then
      if [[ -n "$MISSING_AUTH" ]]; then
        MISSING_AUTH+=", "
      fi
      MISSING_AUTH+="line $LINE_NUM"
    fi
  done
  if [[ -n "$MISSING_AUTH" ]]; then
    add_issue "[P04] $FILE_PATH has @*Mapping without @PreAuthorize at: $MISSING_AUTH. Every endpoint must have @PreAuthorize(\"hasAuthority('resource:action')\")."
  fi
fi

# ══════════════════════════════════════════════════════════
# P05: SQL 迁移无 IF NOT EXISTS
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ \.sql$ ]]; then
  IFNE_LINES=$(grep -in 'IF NOT EXISTS' "$FILE_PATH" 2>/dev/null || true)
  if [[ -n "$IFNE_LINES" ]]; then
    FIRST_IFNE=$(echo "$IFNE_LINES" | head -1)
    add_issue "[P05] $FILE_PATH contains IF NOT EXISTS — Flyway migrations must not use this. Line: $FIRST_IFNE"
  fi
fi

# ══════════════════════════════════════════════════════════
# P06: 前端只用 VITE_APP_BASE_API
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ \.(ts|vue)$ || "$FILE_PATH" =~ \.env ]]; then
  BAD_ENV=$(grep -Pn 'VITE_API_BASE_URL|VITE_BASE_API|VITE_APP_API[^_]' "$FILE_PATH" 2>/dev/null || true)
  if [[ -n "$BAD_ENV" ]]; then
    FIRST_BAD=$(echo "$BAD_ENV" | head -1)
    add_issue "[P06] $FILE_PATH uses wrong env var name — must be VITE_APP_BASE_API only. Line: $FIRST_BAD"
  fi
fi

# ══════════════════════════════════════════════════════════
# P07: POM 无 ${latest.version} 占位符
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ pom\.xml$ ]]; then
  LATEST_HITS=$(grep -n '\${latest.version}' "$FILE_PATH" 2>/dev/null || true)
  if [[ -n "$LATEST_HITS" ]]; then
    FIRST_HIT=$(echo "$LATEST_HITS" | head -1)
    add_issue "[P07] $FILE_PATH contains \${latest.version} placeholder — use hard-coded version number. Line: $FIRST_HIT"
  fi
fi

# ══════════════════════════════════════════════════════════
# P08: 业务表 SQL 有审计列（轻量 — 只检查当前文件）
# 7 列: tenant_id, created_by, created_time, updated_by, updated_time, deleted, version
# Quartz 表 (QRTZ_) 豁免
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ \.sql$ && "$FILE_PATH" =~ migration/ ]]; then
  AUDIT_COLS=(tenant_id created_by created_time updated_by updated_time deleted version)
  # 找所有 CREATE TABLE 语句
  TABLES=$(grep -oPI 'CREATE\s+TABLE\s+\K\S+' "$FILE_PATH" 2>/dev/null || true)
  for TABLE in $TABLES; do
    TABLE_LOWER=$(echo "$TABLE" | tr '[:upper:]' '[:lower:]')
    # 跳过 Quartz 表
    if [[ "$TABLE_LOWER" == *"qrtz_"* ]]; then
      continue
    fi
    TABLE_BLOCK=$(sed -n "/CREATE TABLE.*${TABLE}/I,/);/p" "$FILE_PATH" 2>/dev/null || true)
    MISSING_COLS=""
    for col in "${AUDIT_COLS[@]}"; do
      if ! echo "$TABLE_BLOCK" | grep -qi "$col"; then
        if [[ -n "$MISSING_COLS" ]]; then
          MISSING_COLS+=", "
        fi
        MISSING_COLS+="$col"
      fi
    done
    if [[ -n "$MISSING_COLS" ]]; then
      add_issue "[P08] $FILE_PATH table $TABLE missing audit columns: $MISSING_COLS"
    fi
  done
fi

# ══════════════════════════════════════════════════════════
# P09: Java import 不违反 DAG
# core 不能 import security/data/web
# security 不能 import web
# data 不能 import security/web
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ \.java$ ]]; then
  if [[ "$FILE_PATH" =~ ^ljwx-platform-core/ ]]; then
    BAD_IMPORT=$(grep -n 'import.*ljwx.*\(security\|data\|web\)\.' "$FILE_PATH" 2>/dev/null || true)
    if [[ -n "$BAD_IMPORT" ]]; then
      FIRST_BAD=$(echo "$BAD_IMPORT" | head -1)
      add_issue "[P09] $FILE_PATH DAG violation: core module imports from security/data/web. Line: $FIRST_BAD"
    fi
  fi
  if [[ "$FILE_PATH" =~ ^ljwx-platform-security/ ]]; then
    BAD_IMPORT=$(grep -n 'import.*ljwx.*web\.' "$FILE_PATH" 2>/dev/null || true)
    if [[ -n "$BAD_IMPORT" ]]; then
      FIRST_BAD=$(echo "$BAD_IMPORT" | head -1)
      add_issue "[P09] $FILE_PATH DAG violation: security module imports from web. Line: $FIRST_BAD"
    fi
  fi
  if [[ "$FILE_PATH" =~ ^ljwx-platform-data/ ]]; then
    BAD_IMPORT=$(grep -n 'import.*ljwx.*\(security\|web\)\.' "$FILE_PATH" 2>/dev/null || true)
    if [[ -n "$BAD_IMPORT" ]]; then
      FIRST_BAD=$(echo "$BAD_IMPORT" | head -1)
      add_issue "[P09] $FILE_PATH DAG violation: data module imports from security/web. Line: $FIRST_BAD"
    fi
  fi
fi

# ══════════════════════════════════════════════════════════
# P10: Vue Router v5 API（标记已废弃的 v4 用法）
# ══════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ \.(ts|vue)$ ]]; then
  V4_DEPRECATED=(
    'onBeforeRouteLeave'
    'onBeforeRouteUpdate'
    'useLink'
  )
  for pattern in "${V4_DEPRECATED[@]}"; do
    V4_HIT=$(grep -n "$pattern" "$FILE_PATH" 2>/dev/null | grep -v '^\s*//' | head -1 || true)
    if [[ -n "$V4_HIT" ]]; then
      add_issue "[P10] $FILE_PATH uses deprecated Vue Router v4 API '$pattern' — use v5 equivalent. See https://router.vuejs.org/guide/migration/v4-to-v5. Line: $V4_HIT"
    fi
  done
fi

# ══════════════════════════════════════════════════════════
# 输出结果
# ══════════════════════════════════════════════════════════
if [[ -n "$ISSUES" ]]; then
  # 转义 JSON 特殊字符
  ESCAPED_ISSUES=$(echo "$ISSUES" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/ /g')
  echo "{\"decision\":\"block\",\"reason\":\"$ESCAPED_ISSUES\"}"
  exit 0
fi

# 无问题，静默通过
exit 0
