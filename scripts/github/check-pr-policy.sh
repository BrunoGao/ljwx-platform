#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
PR_NUMBER=""

usage() {
  cat <<USAGE
用法: scripts/github/check-pr-policy.sh [options]

选项:
  --repo <owner/repo>    指定仓库，默认使用 GITHUB_REPOSITORY
  --pr <number>          Pull Request 编号（必填）
  -h, --help             显示帮助
USAGE
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[错误] 缺少命令: $cmd" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:?missing value for --repo}"
      shift 2
      ;;
    --pr)
      PR_NUMBER="${2:?missing value for --pr}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[错误] 未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd gh
require_cmd jq
require_cmd python3

if [[ -z "$REPO" ]]; then
  echo "[错误] 缺少仓库信息，请通过 --repo 指定 owner/repo" >&2
  exit 1
fi

if [[ -z "$PR_NUMBER" ]]; then
  echo "[错误] --pr 为必填参数" >&2
  exit 1
fi

if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "[错误] --pr 必须是数字" >&2
  exit 1
fi

echo "[信息] 开始校验 PR 策略: repo=$REPO pr=#$PR_NUMBER"

PR_JSON="$(gh api "repos/$REPO/pulls/$PR_NUMBER")"
PR_ISSUE_JSON="$(gh api "repos/$REPO/issues/$PR_NUMBER")"
PR_BODY="$(printf '%s' "$PR_JSON" | jq -r '.body // ""')"
PR_TITLE="$(printf '%s' "$PR_JSON" | jq -r '.title // ""')"
PR_MILESTONE="$(printf '%s' "$PR_ISSUE_JSON" | jq -r '.milestone.title // ""')"

violations=()

add_violation() {
  local msg="$1"
  violations+=("$msg")
  echo "[失败] $msg"
}

linked_issues="$(printf '%s' "$PR_BODY" | python3 - <<'PY'
import re
import sys

body = sys.stdin.read()
pattern = r"(?i)\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?|relate[sd]?)\s+#(\d+)"
nums = sorted({int(n) for n in re.findall(pattern, body)})
print(" ".join(str(n) for n in nums))
PY
)"

if [[ -z "$linked_issues" ]]; then
  add_violation "PR 描述必须包含 Closes/Fixes/Resolves/Relates #<issue> 之一"
else
  echo "[通过] 已识别关联 Issue: $linked_issues"
fi

phase_from_line="$(printf '%s' "$PR_BODY" | python3 - <<'PY'
import re
import sys

body = sys.stdin.read()
patterns = [
    r"(?im)^\s*-\s*Phase:\s*#?\s*([0-9]{1,2})\s*$",
    r"(?i)\bphase[-_ ]?([0-9]{1,2})\b",
]
for pattern in patterns:
    match = re.search(pattern, body)
    if match:
        print(match.group(1).zfill(2))
        break
else:
    print("")
PY
)"

spec_path="$(printf '%s' "$PR_BODY" | python3 - <<'PY'
import re
import sys

body = sys.stdin.read()
match = re.search(r"(?i)(spec/phase/phase-([0-9]{2})\.md)", body)
print(match.group(1) if match else "")
PY
)"

phase_from_spec="$(printf '%s' "$PR_BODY" | python3 - <<'PY'
import re
import sys

body = sys.stdin.read()
match = re.search(r"(?i)spec/phase/phase-([0-9]{2})\.md", body)
print(match.group(1) if match else "")
PY
)"

if [[ -z "$phase_from_line" && -z "$phase_from_spec" ]]; then
  add_violation "PR 描述缺少 Phase 信息（示例: - Phase: 27 或 phase-27）"
else
  resolved_phase="$phase_from_line"
  if [[ -z "$resolved_phase" ]]; then
    resolved_phase="$phase_from_spec"
  fi
  echo "[通过] 已识别 Phase: $resolved_phase"
fi

if [[ -z "$spec_path" ]]; then
  add_violation "PR 描述缺少 Spec 路径（示例: spec/phase/phase-27.md）"
else
  if [[ ! -f "$spec_path" ]]; then
    add_violation "Spec 文件不存在: $spec_path"
  else
    echo "[通过] Spec 文件存在: $spec_path"
  fi
fi

if [[ -n "$phase_from_line" && -n "$phase_from_spec" && "$phase_from_line" != "$phase_from_spec" ]]; then
  add_violation "Phase 与 Spec 不一致：Phase=$phase_from_line Spec=$phase_from_spec"
fi

changelog_checked="$(printf '%s' "$PR_BODY" | python3 - <<'PY'
import re
import sys

body = sys.stdin.read()
checked = re.search(r"(?im)^\s*-\s*\[[xX]\]\s*CHANGELOG updated", body) is not None
explicit_skip = re.search(r"(?im)^\s*CHANGELOG\s*:\s*(not needed|n/?a|无需)\s*$", body) is not None
print("true" if (checked or explicit_skip) else "false")
PY
)"

if [[ "$changelog_checked" != "true" ]]; then
  add_violation "CHANGELOG 检查项未勾选（或未显式声明 CHANGELOG: not needed）"
else
  echo "[通过] CHANGELOG 规则已满足"
fi

if [[ -z "$PR_MILESTONE" ]]; then
  add_violation "PR 必须设置 Milestone"
else
  echo "[通过] PR Milestone: $PR_MILESTONE"
fi

if [[ -n "$linked_issues" ]]; then
  missing_issue_milestones=()
  for issue_number in $linked_issues; do
    issue_milestone="$(gh api "repos/$REPO/issues/$issue_number" --jq '.milestone.title // ""' 2>/dev/null || true)"
    if [[ -z "$issue_milestone" ]]; then
      missing_issue_milestones+=("#$issue_number")
    fi
  done

  if [[ "${#missing_issue_milestones[@]}" -gt 0 ]]; then
    add_violation "关联 Issue 缺少 Milestone: ${missing_issue_milestones[*]}"
  else
    echo "[通过] 关联 Issue Milestone 校验通过"
  fi
fi

if [[ "${#violations[@]}" -gt 0 ]]; then
  echo ""
  echo "[结论] PR 策略校验失败（${#violations[@]} 项）"
  printf '  - %s\n' "${violations[@]}"
  echo "[提示] PR 标题: $PR_TITLE"
  exit 1
fi

echo ""
echo "[结论] PR 策略校验通过"
