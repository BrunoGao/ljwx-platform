#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

MISSING_CONTRACTS=0

append_test_cases() {
  local file="$1"
  local base
  base="$(basename "$file")"
  local phase
  phase="$(echo "$base" | sed -E 's/phase-([0-9]{2})\.md/\1/')"

  if rg -q '^## Test Cases' "$file"; then
    return
  fi

  cat >> "$file" <<EOT

## Test Cases

| TC ID | Endpoint | 权限 | 预期状态码 | 关键断言 |
|------|----------|------|------------|---------|
| TC-${phase}-01 | GET /api/** | read | 401 | 无 token 返回 Unauthorized |
| TC-${phase}-02 | GET /api/** | read | 403 | 无权限 token 返回 Forbidden |
| TC-${phase}-03 | GET /api/** | read | 200 | 成功返回统一响应结构 |
| TC-${phase}-04 | POST /api/** | write | 400 | 参数校验错误返回 400 |
| TC-${phase}-05 | POST /api/** | write | 200 | 创建成功并返回 ID/结果 |
| TC-${phase}-06 | PUT /api/**/{id} | write | 200 | 更新成功且可再次查询 |
| TC-${phase}-07 | DELETE /api/**/{id} | delete | 200 | 删除后数据不可见（软删/过滤） |
| TC-${phase}-08 | GET /api/** | read | 200 | 仅可见当前租户数据 |
| TC-${phase}-09 | GET /api/** | read | 401 | 过期 token 被拒绝 |
| TC-${phase}-10 | GET /api/** | read | 401 | 非法 token 被拒绝 |
EOT
}

for file in spec/phase/phase-*.md; do
  append_test_cases "$file"
  contract_ref="$(
    (rg -n -o '`spec/tests/[^`]+\.tests\.yml`|spec/tests/[a-zA-Z0-9._/-]+\.tests\.yml' "$file" -m1 2>/dev/null || true) \
      | head -n1 \
      | sed -E 's/^.*:|`//g'
  )"
  if rg -q '\| 测试契约 \|.*N/A' "$file"; then
    continue
  fi
  if [[ -z "$contract_ref" ]]; then
    echo "Missing test contract reference: $file"
    MISSING_CONTRACTS=$((MISSING_CONTRACTS + 1))
    continue
  fi
  if [[ ! -f "$contract_ref" ]]; then
    echo "Missing test contract file: $contract_ref (from $file)"
    MISSING_CONTRACTS=$((MISSING_CONTRACTS + 1))
    continue
  fi
  if ! rg -q '^ac_tc_map:' "$contract_ref"; then
    echo "Missing ac_tc_map section: $contract_ref"
    MISSING_CONTRACTS=$((MISSING_CONTRACTS + 1))
  fi
done

if [[ "$MISSING_CONTRACTS" -gt 0 ]]; then
  echo "Test Cases ensured, but $MISSING_CONTRACTS contract issues detected."
  exit 1
fi

echo "Test Cases and contracts ensured for all spec/phase files."
