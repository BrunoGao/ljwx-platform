#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

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
done

echo "Test Cases ensured for all spec/phase files."
