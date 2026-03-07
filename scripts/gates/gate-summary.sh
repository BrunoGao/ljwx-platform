#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq first." >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

PHASE_DIR="docs/reports/data/phases"
HISTORY_DIR="docs/reports/data/history"
OUT="docs/reports/data/summary.json"
PHASE_MAP_FILE="spec/phase/logical-phase-map.json"
mkdir -p "$PHASE_DIR" "$HISTORY_DIR"

commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
remote="$(git config --get remote.origin.url 2>/dev/null || true)"
owner="unknown"
repo="unknown"
default_branch="master"
if [[ "$remote" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
fi

run_id="${GITHUB_RUN_ID:-local}"
run_attempt="${GITHUB_RUN_ATTEMPT:-1}"
workflow_name="${GITHUB_WORKFLOW:-gate-local}"
run_url=""
if [[ "$owner" != "unknown" && "$repo" != "unknown" && "$run_id" != "local" ]]; then
  run_url="https://github.com/${owner}/${repo}/actions/runs/${run_id}"
fi

phases_tmp="$(mktemp)"
echo '[]' >"$phases_tmp"

logical_phase_for() {
  local phase="$1"
  local mapped=""
  if [[ -f "$PHASE_MAP_FILE" ]]; then
    mapped="$(jq -r --arg p "$phase" '.physical_to_logical[$p] // empty' "$PHASE_MAP_FILE" 2>/dev/null || true)"
  fi
  if [[ -z "$mapped" ]]; then
    local num=$((10#$phase))
    if ((num >= 1 && num <= 35)); then
      mapped="$num"
    fi
  fi
  if [[ -n "$mapped" ]]; then
    printf '%02d' "$((10#$mapped))"
  fi
}

mapfile -t phase_list < <(
  find spec/phase -maxdepth 1 -type f -name 'phase-[0-9][0-9].md' -printf '%f\n' 2>/dev/null \
    | sed -E 's/^phase-([0-9]{2})\.md$/\1/' \
    | sort -n
)

if [[ "${#phase_list[@]}" -eq 0 ]]; then
  mapfile -t phase_list < <(
    find "$PHASE_DIR" -maxdepth 1 -type f -name 'phase-[0-9][0-9].json' -printf '%f\n' 2>/dev/null \
      | sed -E 's/^phase-([0-9]{2})\.json$/\1/' \
      | sort -n
  )
fi

for phase in "${phase_list[@]}"; do
  logical_phase="$(logical_phase_for "$phase")"
  file="$PHASE_DIR/phase-$phase.json"
  if [[ -f "$file" ]]; then
    item="$(jq -c '
      {
        phase,
        logical_phase: (if $logical_phase=="" then null else $logical_phase end),
        status,
        pass_rate: .summary.pass_rate,
        critical: .summary.critical,
        warnings: .summary.warnings,
        timestamp,
        git_commit: .git.commit,
        r09_status: ((.rules // []) | map(select(.id=="R09")) | .[0].status // "PENDING"),
        gate_status: ((.rules // []) | map({key: .id, value: .status}) | from_entries)
      }' --arg logical_phase "$logical_phase" "$file")"
  else
    item="$(jq -nc --arg p "$phase" --arg logical_phase "$logical_phase" '{phase:$p,logical_phase:(if $logical_phase=="" then null else $logical_phase end),status:"PENDING",pass_rate:0,critical:0,warnings:0,timestamp:"",git_commit:"",r09_status:"PENDING",gate_status:{}}')"
  fi
  jq --argjson item "$item" '. + [$item]' "$phases_tmp" >"$phases_tmp.next" && mv "$phases_tmp.next" "$phases_tmp"
done

logical_tmp="$(mktemp)"
jq -n --slurpfile phases "$phases_tmp" '
  def agg_status($arr):
    if ($arr | index("FAIL")) then "FAIL"
    elif ($arr | index("PASS")) then "PASS"
    elif ($arr | index("SKIP")) then "SKIP"
    else "PENDING"
    end;
  def agg_gate_status($gate_maps):
    ["R01","R02","R03","R04","R05","R06","R07","R08","R09","R10","R11"]
    | map(. as $rule | {
        key: $rule,
        value: (
          ($gate_maps | map(.[$rule] // "PENDING")) as $vals
          | agg_status($vals)
        )
      })
    | from_entries;
  [range(1;36)] | map(
    (if . < 10 then "0\(.)" else "\(.)" end) as $lp
    | ($phases[0] | map(select(.logical_phase == $lp))) as $group
    | if ($group | length) == 0 then
        {
          logical_phase: $lp,
          source_phases: [],
          status: "PENDING",
          pass_rate: 0,
          critical: 0,
          warnings: 0,
          r09_status: "PENDING",
          gate_status: {}
        }
      else
        {
          logical_phase: $lp,
          source_phases: ($group | map(.phase) | unique | sort),
          status: agg_status($group | map(.status)),
          pass_rate: ((((($group | map(.pass_rate // 0) | add) / ($group | length)) * 100) | round) / 100),
          critical: ($group | map(.critical // 0) | add),
          warnings: ($group | map(.warnings // 0) | add),
          r09_status: agg_status($group | map(.r09_status)),
          gate_status: agg_gate_status($group | map(.gate_status // {}))
        }
      end
  )
' >"$logical_tmp"

history_tmp="$(mktemp)"
echo '[]' >"$history_tmp"
if ls "$HISTORY_DIR"/*.json >/dev/null 2>&1; then
  ls -1t "$HISTORY_DIR"/*.json | head -n 50 | while read -r f; do
    entry="$(jq -c '
      {
        timestamp,
        phase,
        status,
        pass_rate: .summary.pass_rate,
        git_commit: .git.commit,
        critical: .summary.critical,
        warnings: .summary.warnings,
        run_id: (.ci.run_id // null),
        run_url: (.ci.run_url // null)
      }' "$f" 2>/dev/null || echo '{}')"
    jq --argjson e "$entry" '. + [$e]' "$history_tmp" >"$history_tmp.next" && mv "$history_tmp.next" "$history_tmp"
  done
fi

totals="$(jq -c '
  {
    pass: (map(select(.status=="PASS"))|length),
    fail: (map(select(.status=="FAIL"))|length),
    pending: (map(select(.status=="PENDING"))|length),
    critical: (map(.critical // 0)|add),
    warnings: (map(.warnings // 0)|add)
  }
' "$phases_tmp")"

logical_totals="$(jq -c '
  {
    pass: (map(select(.status=="PASS"))|length),
    fail: (map(select(.status=="FAIL"))|length),
    pending: (map(select(.status=="PENDING"))|length),
    critical: (map(.critical // 0)|add),
    warnings: (map(.warnings // 0)|add)
  }
' "$logical_tmp")"

jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg owner "$owner" \
  --arg name "$repo" \
  --arg default_branch "$default_branch" \
  --arg branch "$branch" \
  --arg commit "$commit" \
  --arg run_id "$run_id" \
  --arg run_attempt "$run_attempt" \
  --arg workflow_name "$workflow_name" \
  --arg run_url "$run_url" \
  --argjson totals "$totals" \
  --argjson logical_totals "$logical_totals" \
  --slurpfile phases "$phases_tmp" \
  --slurpfile logical_phases "$logical_tmp" \
  --slurpfile history "$history_tmp" \
  '{
    generated_at: $ts,
    repo: {owner: $owner, name: $name, default_branch: $default_branch},
    git: {branch: $branch, commit: $commit, short: $commit},
    ci: {
      run_id: (if $run_id == "local" then null else ($run_id | tonumber) end),
      run_attempt: ($run_attempt | tonumber),
      workflow: $workflow_name,
      run_url: (if $run_url == "" then null else $run_url end)
    },
    totals: $totals,
    phases: $phases[0],
    logical_totals: $logical_totals,
    logical_phases: $logical_phases[0],
    history: $history[0]
  }' >"$OUT"

echo "$OUT"
