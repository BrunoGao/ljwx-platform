#!/usr/bin/env bash
# PostToolUse hook — reads the ACTUAL file on disk after Edit/Write completes.
# All content checks operate on the real file, not on tool_input JSON fields.
# Outputs a block decision JSON if issues are found.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

ISSUES=""

# Rule no-caret: package.json must not use ^ versions
if [[ "$FILE_PATH" == *"package.json"* ]]; then
  if grep -q '"^' "$FILE_PATH"; then
    HITS=$(grep -n '"^' "$FILE_PATH" | head -3 | tr '\n' '; ')
    ISSUES="${ISSUES}[no-caret] $FILE_PATH: caret (^) found — use tilde (~). Lines: ${HITS}"
  fi
fi

# Rule dto-no-tenant-id: DTO must not expose tenantId
if [[ "$FILE_PATH" =~ (DTO|Dto|Request|Response)\.java$ ]]; then
  if grep -qiE '(private|protected|public)[[:space:]]+[^[:space:]]+[[:space:]]+tenantId' "$FILE_PATH"; then
    LINE=$(grep -niE '(private|protected|public)[[:space:]]+[^[:space:]]+[[:space:]]+tenantId' "$FILE_PATH" | head -1)
    ISSUES="${ISSUES}[dto-no-tenant-id] $FILE_PATH: DTO exposes tenantId ($LINE). Remove it. "
  fi
fi

# Rule no-any: TypeScript must not use 'any' type
if [[ "$FILE_PATH" =~ \.(ts|vue)$ ]]; then
  ANY_LINE=$(grep -En '(:[[:space:]]*any[^a-zA-Z_]|as any[^a-zA-Z_]|<any>)' "$FILE_PATH" \
    | grep -v '^\s*//' \
    | grep -v '//.*:\s*any' \
    | head -1 || true)
  if [[ -n "$ANY_LINE" ]]; then
    ISSUES="${ISSUES}[no-any] $FILE_PATH: 'any' type at: $ANY_LINE — use proper type. "
  fi
fi

# Rule no-if-not-exists: Flyway SQL must not use IF NOT EXISTS
if [[ "$FILE_PATH" =~ \.sql$ ]]; then
  if grep -qi 'IF NOT EXISTS' "$FILE_PATH"; then
    LINE=$(grep -ni 'IF NOT EXISTS' "$FILE_PATH" | head -1)
    ISSUES="${ISSUES}[no-if-not-exists] $FILE_PATH: IF NOT EXISTS found ($LINE). "
  fi
fi

# Rule wrong-env-var: must use VITE_APP_BASE_API
if [[ "$FILE_PATH" =~ \.(ts|vue)$ ]] || [[ "$FILE_PATH" =~ \.env ]]; then
  if grep -qE 'VITE_API_BASE_URL|VITE_BASE_API' "$FILE_PATH"; then
    LINE=$(grep -nE 'VITE_API_BASE_URL|VITE_BASE_API' "$FILE_PATH" | head -1)
    ISSUES="${ISSUES}[wrong-env-var] $FILE_PATH: wrong env var ($LINE) — must be VITE_APP_BASE_API. "
  fi
fi

# Rule no-preauthorize: Controller @*Mapping must have @PreAuthorize
if [[ "$FILE_PATH" =~ Controller\.java$ ]]; then
  MAPPING_LINES=$(grep -n '@\(Get\|Post\|Put\|Delete\|Patch\)Mapping' "$FILE_PATH" | cut -d: -f1 || true)
  for LINE_NUM in $MAPPING_LINES; do
    LINE_CONTENT=$(sed -n "${LINE_NUM}p" "$FILE_PATH")
    if echo "$LINE_CONTENT" | grep -qiE '(login|refresh)'; then
      continue
    fi
    START=$((LINE_NUM > 5 ? LINE_NUM - 5 : 1))
    CONTEXT=$(sed -n "${START},${LINE_NUM}p" "$FILE_PATH")
    if echo "$CONTEXT" | grep -q '@PreAuthorize'; then
      : # has @PreAuthorize, ok
    else
      ISSUES="${ISSUES}[no-preauthorize] $FILE_PATH:$LINE_NUM: @*Mapping without @PreAuthorize. "
      break
    fi
  done
fi

# Rule no-latest-version: POM must not use ${latest.version}
if [[ "$FILE_PATH" =~ pom\.xml$ ]]; then
  if grep -q '\${latest\.version}' "$FILE_PATH"; then
    LINE=$(grep -n '\${latest\.version}' "$FILE_PATH" | head -1)
    ISSUES="${ISSUES}[no-latest-version] $FILE_PATH: \${latest.version} found ($LINE). "
  fi
fi

if [[ -n "$ISSUES" ]]; then
  SAFE=$(printf '%s' "$ISSUES" | sed 's/"/\\"/g')
  printf '{"decision":"block","reason":"%s"}\n' "$SAFE"
fi

exit 0
