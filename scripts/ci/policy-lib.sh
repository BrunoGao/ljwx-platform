#!/usr/bin/env bash
set -euo pipefail

POLICY_FILE="${CLOSED_LOOP_POLICY_FILE:-scripts/ci/closed-loop-policy.json}"

policy_get() {
  local key="$1"
  local default="$2"
  if [[ -f "$POLICY_FILE" ]]; then
    local v
    v="$(
      jq -r --arg key "$key" '
        ($key | split(".")) as $p
        | (try getpath($p) catch "__MISSING__") as $v
        | if $v == "__MISSING__" or $v == null then
            ""
          else
            ($v | tostring)
          end
      ' "$POLICY_FILE" 2>/dev/null || true
    )"
    if [[ -n "$v" ]]; then
      echo "$v"
      return 0
    fi
  fi
  echo "$default"
}

policy_get_bool() {
  local key="$1"
  local default="$2"
  local raw
  raw="$(policy_get "$key" "$default")"
  local lowered
  lowered="$(echo "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$lowered" in
    true|1|yes|y|on) echo "true" ;;
    false|0|no|n|off) echo "false" ;;
    *) echo "$default" ;;
  esac
}

_policy_state_file() {
  policy_get 'global.breaker_state_file' 'artifacts/closed-loop/breakers/state.json'
}

_policy_event_log_file() {
  policy_get 'global.event_log_file' 'artifacts/closed-loop/breakers/events.jsonl'
}

_ensure_breaker_files() {
  local state_file event_log
  state_file="$(_policy_state_file)"
  event_log="$(_policy_event_log_file)"
  mkdir -p "$(dirname "$state_file")" "$(dirname "$event_log")"
  [[ -f "$state_file" ]] || echo '{}' >"$state_file"
  [[ -f "$event_log" ]] || : >"$event_log"
}

_cb_event() {
  local name="$1"
  local action="$2"
  local reason="${3:-}"
  local state_file event_log
  state_file="$(_policy_state_file)"
  event_log="$(_policy_event_log_file)"

  local now
  now="$(date +%s)"

  jq -n \
    --arg name "$name" \
    --arg action "$action" \
    --arg reason "$reason" \
    --argjson at "$now" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{timestamp:$ts,at:$at,name:$name,action:$action,reason:$reason}' >>"$event_log"
}

cb_is_open() {
  local name="$1"
  _ensure_breaker_files
  local state_file now open_until
  state_file="$(_policy_state_file)"
  now="$(date +%s)"
  open_until="$(jq -r --arg name "$name" '.[$name].openUntil // 0' "$state_file" 2>/dev/null || echo 0)"
  [[ "$open_until" =~ ^[0-9]+$ ]] || open_until=0
  if (( now < open_until )); then
    return 0
  fi
  return 1
}

cb_allow_or_exit() {
  local name="$1"
  _ensure_breaker_files
  local state_file now open_until
  state_file="$(_policy_state_file)"
  now="$(date +%s)"
  open_until="$(jq -r --arg name "$name" '.[$name].openUntil // 0' "$state_file" 2>/dev/null || echo 0)"
  [[ "$open_until" =~ ^[0-9]+$ ]] || open_until=0
  if (( now < open_until )); then
    local wait_sec=$((open_until - now))
    echo "[circuit-breaker] OPEN: ${name}, cool down ${wait_sec}s"
    _cb_event "$name" "blocked" "open_until=${open_until}"
    exit 23
  fi
}

cb_record_success() {
  local name="$1"
  _ensure_breaker_files
  local state_file tmp now
  state_file="$(_policy_state_file)"
  tmp="$(mktemp)"
  now="$(date +%s)"

  jq \
    --arg name "$name" \
    --argjson now "$now" \
    '
    .[$name] = ((.[$name] // {}) + {
      name: $name,
      consecutiveFailures: 0,
      lastSuccessAt: $now,
      openUntil: 0
    })
    ' "$state_file" >"$tmp"
  mv "$tmp" "$state_file"
  _cb_event "$name" "success" ""
}

cb_record_failure() {
  local name="$1"
  local threshold="$2"
  local cooldown_sec="$3"
  _ensure_breaker_files

  local state_file tmp now
  state_file="$(_policy_state_file)"
  tmp="$(mktemp)"
  now="$(date +%s)"

  jq \
    --arg name "$name" \
    --argjson threshold "$threshold" \
    --argjson cooldown "$cooldown_sec" \
    --argjson now "$now" \
    '
    .[$name] = (
      (.[$name] // {consecutiveFailures:0})
      | .name = $name
      | .consecutiveFailures = ((.consecutiveFailures // 0) + 1)
      | .lastFailureAt = $now
      | if .consecutiveFailures >= $threshold then
          .openUntil = ($now + $cooldown)
        else
          .openUntil = (.openUntil // 0)
        end
    )
    ' "$state_file" >"$tmp"
  mv "$tmp" "$state_file"

  local open_until
  open_until="$(jq -r --arg name "$name" '.[$name].openUntil // 0' "$state_file")"
  if [[ "$open_until" =~ ^[0-9]+$ ]] && (( open_until > now )); then
    _cb_event "$name" "open" "threshold=${threshold},cooldown=${cooldown_sec}"
  else
    _cb_event "$name" "failure" "threshold=${threshold}"
  fi
}
