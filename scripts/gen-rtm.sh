#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq first." >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

OUT="docs/reports/data/rtm.json"
PHASE_REPORT_DIR="docs/reports/data/phases"
PHASE_SPEC_DIR="spec/phase"
PHASE_MAP_FILE="spec/phase/logical-phase-map.json"
TEST_ROOT="ljwx-platform-app/src/test/java"
mkdir -p "$(dirname "$OUT")"

matrix_tmp="$(mktemp)"
missing_tmp="$(mktemp)"
summary_tmp="$(mktemp)"
phase_cov_tmp="$(mktemp)"
echo '[]' >"$matrix_tmp"
echo '[]' >"$missing_tmp"

declare -A FILE_PHASE_MAP
declare -A PHASE_STATUS_MAP

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

escape_regex() {
  echo "$1" | sed -E 's/[][(){}.+*^$|?\\]/\\&/g'
}

detect_test_file() {
  local method="$1"
  local endpoint="$2"
  local method_lc
  method_lc="$(echo "$method" | tr '[:upper:]' '[:lower:]')"
  local method_fn=""
  case "$method_lc" in
    get) method_fn="performGet|get\\(" ;;
    post) method_fn="performPost|post\\(" ;;
    put) method_fn="performPut|put\\(" ;;
    delete) method_fn="performDelete|delete\\(" ;;
    patch) method_fn="patch\\(" ;;
  esac
  [[ -z "$method_fn" ]] && return 0

  local endpoint_prefix="$endpoint"
  endpoint_prefix="${endpoint_prefix%%\{*}"
  [[ -z "$endpoint_prefix" ]] && endpoint_prefix="$endpoint"

  if [[ ! -d "$TEST_ROOT" ]]; then
    return 0
  fi

  local endpoint_re
  endpoint_re="$(escape_regex "$endpoint_prefix")"
  local hit
  hit="$(grep -RIlE "$endpoint_re" "$TEST_ROOT" 2>/dev/null | while read -r f; do
      if grep -Eq "$method_fn" "$f"; then
        echo "$f"
        break
      fi
    done)"
  if [[ -n "$hit" ]]; then
    echo "$hit"
  fi
}

load_phase_scope_map() {
  if [[ ! -d "$PHASE_SPEC_DIR" ]]; then
    return
  fi
  while IFS= read -r spec; do
    [[ -f "$spec" ]] || continue
    local phase
    phase="$(basename "$spec" | sed -E 's/^phase-([0-9]{2})\.md$/\1/')"
    [[ -z "$phase" ]] && continue
    local in_scope=false
    local in_frontmatter=false
    while IFS= read -r line; do
      if [[ "$line" == "---" && "$in_frontmatter" == false ]]; then
        in_frontmatter=true
        continue
      fi
      if [[ "$line" == "---" && "$in_frontmatter" == true ]]; then
        break
      fi
      if [[ "$in_frontmatter" == false ]]; then
        continue
      fi
      if [[ "$line" =~ ^scope:[[:space:]]*$ ]]; then
        in_scope=true
        continue
      fi
      if [[ "$in_scope" == true ]]; then
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]* ]]; then
          local entry
          entry="$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^"//; s/"$//')"
          entry="${entry#./}"
          [[ -z "$entry" ]] && continue
          if [[ "$entry" == *"*"* ]]; then
            continue
          fi
          local old_phase="${FILE_PHASE_MAP[$entry]:-}"
          if [[ -z "$old_phase" || "$((10#$phase))" -gt "$((10#$old_phase))" ]]; then
            FILE_PHASE_MAP["$entry"]="$phase"
          fi
        elif [[ "$line" =~ ^[a-zA-Z_]+: ]]; then
          in_scope=false
        fi
      fi
    done <"$spec"
  done < <(find "$PHASE_SPEC_DIR" -maxdepth 1 -type f -name 'phase-[0-9][0-9].md' | sort)
}

load_phase_status_map() {
  if [[ ! -d "$PHASE_REPORT_DIR" ]]; then
    return
  fi
  while IFS= read -r report; do
    [[ -f "$report" ]] || continue
    local phase
    phase="$(basename "$report" | sed -E 's/^phase-([0-9]{2})\.json$/\1/')"
    [[ -z "$phase" ]] && continue
    PHASE_STATUS_MAP["$phase"]="$(jq -r '.status // "PENDING"' "$report" 2>/dev/null || echo "PENDING")"
  done < <(find "$PHASE_REPORT_DIR" -maxdepth 1 -type f -name 'phase-[0-9][0-9].json' | sort)
}

phase_for_file() {
  local file="$1"
  file="${file#./}"
  if [[ -n "${FILE_PHASE_MAP[$file]:-}" ]]; then
    echo "${FILE_PHASE_MAP[$file]}"
  fi
}

load_phase_scope_map
load_phase_status_map

while IFS= read -r controller; do
  [[ -z "$controller" ]] && continue
  controller="${controller#./}"
  base_path="$(grep -E '@RequestMapping\("[^"]+"\)' "$controller" 2>/dev/null | head -n1 | sed -E 's/.*\("([^"]+)"\).*/\1/' || true)"
  [[ -z "$base_path" ]] && base_path=""

  while IFS= read -r line; do
    method="$(echo "$line" | sed -E 's/.*@(Get|Post|Put|Delete|Patch)Mapping.*/\1/' | tr '[:lower:]' '[:upper:]')"
    suffix="$(echo "$line" | sed -E 's/.*Mapping\("([^"]*)"\).*/\1/' || true)"
    if [[ "$suffix" == "$line" ]]; then
      suffix=""
    fi
    endpoint="$base_path$suffix"
    service_guess="${controller%Controller.java}Service.java"
    [[ -f "$service_guess" ]] || service_guess=""

    phase="$(phase_for_file "$controller")"
    if [[ -z "$phase" && -n "$service_guess" ]]; then
      phase="$(phase_for_file "$service_guess")"
    fi

    logical_phase=""
    gate_status="PENDING"
    if [[ -n "$phase" ]]; then
      logical_phase="$(logical_phase_for "$phase")"
      gate_status="${PHASE_STATUS_MAP[$phase]:-PENDING}"
    fi

    test_file="$(detect_test_file "$method" "$endpoint")"
    test_covered="false"
    if [[ -n "$test_file" ]]; then
      test_covered="true"
    fi

    item="$(jq -nc \
      --arg phase "$phase" \
      --arg logical_phase "$logical_phase" \
      --arg endpoint "$endpoint" \
      --arg method "$method" \
      --arg controller "$controller" \
      --arg service "$service_guess" \
      --arg test "$test_file" \
      --argjson test_covered "$test_covered" \
      --arg gate_status "$gate_status" \
      '{
        phase: (if $phase=="" then null else $phase end),
        logical_phase: (if $logical_phase=="" then null else $logical_phase end),
        requirement_id: null,
        endpoint: (if $endpoint=="" then null else $endpoint end),
        method: (if $method=="" then null else $method end),
        controller: $controller,
        service: (if $service=="" then null else $service end),
        test: (if $test=="" then null else $test end),
        test_covered: $test_covered,
        spec: null,
        gate_status: $gate_status
      }')"

    jq --argjson i "$item" '. + [$i]' "$matrix_tmp" >"$matrix_tmp.next" && mv "$matrix_tmp.next" "$matrix_tmp"
  done < <(grep -E '@(Get|Post|Put|Delete|Patch)Mapping\(' "$controller" 2>/dev/null || true)
done < <(find ljwx-platform-app/src/main/java -name '*Controller.java' 2>/dev/null | sort)

if [[ ! -d "$PHASE_SPEC_DIR" ]]; then
  jq '. + ["spec/phase"]' "$missing_tmp" >"$missing_tmp.next" && mv "$missing_tmp.next" "$missing_tmp"
fi

jq '{
  total_endpoints: length,
  covered_endpoints: (map(select(.test_covered == true)) | length),
  uncovered_endpoints: (map(select(.test_covered != true)) | length),
  coverage_percent: (
    if length == 0 then 0
    else (((map(select(.test_covered == true)) | length) * 10000 / length) | round) / 100
    end
  )
}' "$matrix_tmp" >"$summary_tmp"

jq '
  map(select(.phase != null))
  | sort_by(.phase)
  | group_by(.phase)
  | map({
      phase: .[0].phase,
      logical_phase: (.[0].logical_phase // null),
      total_endpoints: length,
      covered_endpoints: (map(select(.test_covered == true)) | length),
      uncovered_endpoints: (map(select(.test_covered != true)) | length),
      coverage_percent: (
        if length == 0 then 0
        else (((map(select(.test_covered == true)) | length) * 10000 / length) | round) / 100
        end
      )
    })
' "$matrix_tmp" >"$phase_cov_tmp"

jq -n \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --slurpfile matrix "$matrix_tmp" \
  --slurpfile summary "$summary_tmp" \
  --slurpfile phase_coverage "$phase_cov_tmp" \
  --slurpfile missing "$missing_tmp" \
  '{
    generated_at: $generated_at,
    summary: $summary[0],
    phase_coverage: $phase_coverage[0],
    matrix: $matrix[0],
    missing_files: $missing[0]
  }' >"$OUT"

echo "$OUT"
