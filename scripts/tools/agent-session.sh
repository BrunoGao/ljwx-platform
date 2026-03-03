#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SESSION_PREFIX="${AGENT_SESSION_PREFIX:-ljwx-agent}"
DEFAULT_SESSION="${SESSION_PREFIX}-codex"

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/tools/agent-session.sh start <codex|claude> [session]
  bash scripts/tools/agent-session.sh attach [session]
  bash scripts/tools/agent-session.sh status
  bash scripts/tools/agent-session.sh stop <session>

Examples:
  bash scripts/tools/agent-session.sh start codex
  bash scripts/tools/agent-session.sh start claude ljwx-agent-claude-main
  bash scripts/tools/agent-session.sh attach ljwx-agent-codex
USAGE
}

require_tmux() {
  if ! command -v tmux >/dev/null 2>&1; then
    echo "错误: 未检测到 tmux，请先安装 tmux 后再执行。"
    echo "Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y tmux"
    echo "RHEL/CentOS: sudo yum install -y tmux"
    exit 1
  fi
}

ensure_agent_cmd() {
  local agent="$1"
  if ! command -v "$agent" >/dev/null 2>&1; then
    echo "错误: 未检测到命令 '$agent'，请先安装并配置后再执行。"
    exit 1
  fi
}

validate_agent() {
  local agent="$1"
  case "$agent" in
    codex|claude) ;;
    *)
      echo "错误: 不支持的 agent '$agent'，仅支持 codex 或 claude。"
      exit 1
      ;;
  esac
}

session_exists() {
  local session="$1"
  tmux has-session -t "$session" 2>/dev/null
}

start_session() {
  local agent="$1"
  local session="$2"

  validate_agent "$agent"
  ensure_agent_cmd "$agent"

  if session_exists "$session"; then
    echo "会话已存在: $session，正在恢复..."
    exec tmux attach -t "$session"
  fi

  tmux new-session -d -s "$session" -c "$PROJECT_ROOT"
  tmux set-option -t "$session" -g history-limit 200000 >/dev/null
  tmux set-option -t "$session" -g remain-on-exit on >/dev/null

  tmux send-keys -t "$session" "cd '$PROJECT_ROOT' && $agent" C-m

  echo "已创建会话: $session"
  echo "SSH 断开不会影响会话中的 $agent 进程。"
  exec tmux attach -t "$session"
}

attach_session() {
  local session="$1"
  if ! session_exists "$session"; then
    echo "错误: 会话不存在: $session"
    echo "提示: 先执行 start 创建会话。"
    exit 1
  fi
  exec tmux attach -t "$session"
}

show_status() {
  if ! tmux ls 2>/dev/null; then
    echo "当前没有 tmux 会话。"
    exit 0
  fi
}

stop_session() {
  local session="$1"
  if ! session_exists "$session"; then
    echo "错误: 会话不存在: $session"
    exit 1
  fi
  tmux kill-session -t "$session"
  echo "已停止会话: $session"
}

main() {
  require_tmux

  local action="${1:-}"
  case "$action" in
    start)
      local agent="${2:-}"
      local session="${3:-${SESSION_PREFIX}-${agent}}"
      if [[ -z "$agent" ]]; then
        usage
        exit 1
      fi
      start_session "$agent" "$session"
      ;;
    attach)
      local session="${2:-$DEFAULT_SESSION}"
      attach_session "$session"
      ;;
    status)
      show_status
      ;;
    stop)
      local session="${2:-}"
      if [[ -z "$session" ]]; then
        usage
        exit 1
      fi
      stop_session "$session"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
