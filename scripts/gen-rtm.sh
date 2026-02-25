#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq first." >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

OUT="docs/reports/data/rtm.json"
PHASE_DIR="docs/reports/data/phases"
mkdir -p "$(dirname "$OUT")"

matrix_tmp="$(mktemp)"
missing_tmp="$(mktemp)"
echo '[]' >"$matrix_tmp"
echo '[]' >"$missing_tmp"

while IFS= read -r controller; do
  [[ -z "$controller" ]] && continue
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
    [[ -f "$service_guess" ]] || service_guess=null

    phase="null"
    req_id="null"
    gate_status="PENDING"

    for p in "$PHASE_DIR"/phase-*.json; do
      [[ -f "$p" ]] || continue
      st="$(jq -r '.status' "$p" 2>/dev/null || echo PENDING)"
      ph="$(jq -r '.phase' "$p" 2>/dev/null || echo null)"
      if [[ "$phase" == "null" ]]; then
        phase="$ph"
        gate_status="$st"
      fi
    done

    item="$(jq -nc \
      --arg phase "$phase" \
      --arg requirement_id "$req_id" \
      --arg endpoint "$endpoint" \
      --arg method "$method" \
      --arg controller "$controller" \
      --arg service "$service_guess" \
      --arg test null \
      --arg spec null \
      --arg gate_status "$gate_status" \
      '{
        phase: (if $phase=="null" then null else $phase end),
        requirement_id: (if $requirement_id=="null" then null else $requirement_id end),
        endpoint: (if $endpoint=="" then null else $endpoint end),
        method: (if $method=="" then null else $method end),
        controller: $controller,
        service: (if $service=="null" then null else $service end),
        test: null,
        spec: null,
        gate_status: $gate_status
      }')"

    jq --argjson i "$item" '. + [$i]' "$matrix_tmp" >"$matrix_tmp.next" && mv "$matrix_tmp.next" "$matrix_tmp"
  done < <(grep -E '@(Get|Post|Put|Delete|Patch)Mapping\(' "$controller" 2>/dev/null || true)
done < <(find ljwx-platform-app/src/main/java -name '*Controller.java' 2>/dev/null | sort)

if [[ ! -d "spec/phase" ]]; then
  jq '. + ["spec/phase"]' "$missing_tmp" >"$missing_tmp.next" && mv "$missing_tmp.next" "$missing_tmp"
fi

jq -n \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --slurpfile matrix "$matrix_tmp" \
  --slurpfile missing "$missing_tmp" \
  '{generated_at:$generated_at,matrix:$matrix[0],missing_files:$missing[0]}' >"$OUT"

echo "$OUT"
