#!/usr/bin/env bash
set -euo pipefail

TARGET_RC="${1:-$HOME/.zshrc}"
BLOCK_BEGIN="# >>> ljwx-agent auto-attach >>>"
BLOCK_END="# <<< ljwx-agent auto-attach <<<"

if [[ ! -f "$TARGET_RC" ]]; then
  echo "错误: 配置文件不存在: $TARGET_RC"
  exit 1
fi

if ! rg -F "$BLOCK_BEGIN" "$TARGET_RC" >/dev/null 2>&1; then
  echo "未检测到自动回连配置，无需移除。"
  echo "配置文件: $TARGET_RC"
  exit 0
fi

BACKUP_PATH="${TARGET_RC}.bak.$(date +%Y%m%d%H%M%S)"
cp "$TARGET_RC" "$BACKUP_PATH"

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

awk -v begin="$BLOCK_BEGIN" -v end="$BLOCK_END" '
  $0 == begin {
    skip = 1
    removed = 1
    next
  }
  $0 == end {
    skip = 0
    next
  }
  !skip {
    print
  }
  END {
    if (!removed) {
      exit 2
    }
  }
' "$TARGET_RC" > "$TEMP_FILE"

mv "$TEMP_FILE" "$TARGET_RC"

echo "已移除 SSH 自动回连/登录菜单配置。"
echo "配置文件: $TARGET_RC"
echo "备份文件: $BACKUP_PATH"
echo "提示: 重新 SSH 登录后将直接进入服务器 Shell。"
