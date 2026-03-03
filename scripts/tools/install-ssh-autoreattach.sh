#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEFAULT_SESSION="${AGENT_AUTO_SESSION:-ljwx-agent-codex}"
TARGET_RC="${1:-$HOME/.zshrc}"

BLOCK_BEGIN="# >>> ljwx-agent auto-attach >>>"
BLOCK_END="# <<< ljwx-agent auto-attach <<<"

if ! command -v tmux >/dev/null 2>&1; then
  echo "错误: 未检测到 tmux，请先安装 tmux 后再执行。"
  exit 1
fi

if [[ ! -f "$TARGET_RC" ]]; then
  touch "$TARGET_RC"
fi

if rg -n "$BLOCK_BEGIN" "$TARGET_RC" >/dev/null 2>&1; then
  echo "已存在自动回连配置，无需重复安装。"
  echo "配置文件: $TARGET_RC"
  exit 0
fi

cat >> "$TARGET_RC" <<EOF_BLOCK

$BLOCK_BEGIN
if [[ -n "\${SSH_CONNECTION:-}" ]] && [[ -z "\${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  tmux attach -t "$DEFAULT_SESSION" || bash "$PROJECT_ROOT/scripts/tools/agent-session.sh" start codex "$DEFAULT_SESSION"
fi
$BLOCK_END
EOF_BLOCK

echo "安装完成: 已写入 SSH 自动回连配置。"
echo "配置文件: $TARGET_RC"
echo "默认会话: $DEFAULT_SESSION"
echo "提示: 重连 SSH 后会自动进入该会话。"
