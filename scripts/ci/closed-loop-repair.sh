#!/usr/bin/env bash
set -euo pipefail

DIAGNOSIS=""
RECIPES="scripts/ci/repair-recipes.yaml"
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diagnosis) DIAGNOSIS="$2"; shift 2 ;;
    --recipes)   RECIPES="$2";   shift 2 ;;
    --output)    OUTPUT="$2";    shift 2 ;;
    *) echo "[repair] Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$DIAGNOSIS" || -z "$OUTPUT" ]]; then
  echo "[repair] Usage: $0 --diagnosis <diagnosis.json> --output <repair.json> [--recipes path]" >&2
  exit 2
fi

if [[ ! -f "$DIAGNOSIS" ]]; then
  echo "[repair] diagnosis file not found: $DIAGNOSIS" >&2
  exit 2
fi

if [[ ! -f "$RECIPES" ]]; then
  echo "[repair] recipes file not found: $RECIPES" >&2
  exit 2
fi

WORK_DIR="$(dirname "$OUTPUT")"
LOG_DIR="${WORK_DIR}/repair-logs"
mkdir -p "$WORK_DIR" "$LOG_DIR"

PLAN_FILE="$(mktemp)"
RESULTS_FILE="$(mktemp)"
echo "[]" >"$RESULTS_FILE"

python3 - "$DIAGNOSIS" "$RECIPES" "$PLAN_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone

diagnosis_path, recipes_path, plan_path = sys.argv[1:]

def clean(v):
    v = v.strip()
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        v = v[1:-1]
    return v

def parse_simple_yaml(path):
    recipes = []
    cur = None
    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if stripped == "repairs:":
                continue
            if stripped.startswith("- "):
                if cur:
                    recipes.append(cur)
                cur = {}
                rest = stripped[2:].strip()
                if rest and ":" in rest:
                    k, v = rest.split(":", 1)
                    cur[k.strip()] = clean(v)
                continue
            if cur is None:
                continue
            if ":" in stripped:
                k, v = stripped.split(":", 1)
                cur[k.strip()] = clean(v)
    if cur:
        recipes.append(cur)
    return recipes

diag = json.load(open(diagnosis_path, "r", encoding="utf-8"))
recipes = parse_simple_yaml(recipes_path)

actions = []
used = set()

for d in diag.get("diagnoses", []):
    if d.get("repairability") not in {"auto", "mitigate"}:
        continue

    keys = []
    keys.extend(d.get("recommendedRecipes") or [])
    keys.extend(d.get("signals") or [])
    if d.get("check"):
        keys.append(str(d["check"]))
    norm_keys = {str(k).strip().lower() for k in keys if str(k).strip()}

    matched = None
    for r in recipes:
        r_check = str(r.get("check") or "").strip().lower()
        r_id = str(r.get("id") or "").strip().lower()
        if not r_check and not r_id:
            continue
        if r_check in norm_keys or r_id in norm_keys:
            matched = r
            break

    # Category fallback: pick a same-category recipe with the same mode if direct match missing.
    if matched is None:
        for r in recipes:
            if str(r.get("category", "")).upper() == str(d.get("category", "")).upper():
                if d.get("repairability") == "mitigate" and str(r.get("mode", "")).lower() == "mitigate":
                    matched = r
                    break
                if d.get("repairability") == "auto" and str(r.get("mode", "")).lower() == "auto":
                    matched = r
                    break

    if matched is None:
        continue

    rid = str(matched.get("id") or "")
    if not rid or rid in used:
        continue
    used.add(rid)
    try:
        max_attempts = int(matched.get("max_attempts") or 1)
    except Exception:
        max_attempts = 1
    if max_attempts < 1:
        max_attempts = 1

    actions.append(
        {
            "id": rid,
            "check": matched.get("check"),
            "category": matched.get("category"),
            "mode": matched.get("mode"),
            "type": matched.get("type"),
            "cmd": matched.get("cmd"),
            "max_attempts": max_attempts,
            "diagnosis_check": d.get("check"),
            "diagnosis_category": d.get("category"),
            "diagnosis_repairability": d.get("repairability"),
        }
    )

plan = {
    "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "input": {"diagnosis": diagnosis_path, "recipes": recipes_path},
    "actions": actions,
}
json.dump(plan, open(plan_path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY

ACTION_COUNT="$(jq '.actions | length' "$PLAN_FILE")"
if [[ "$ACTION_COUNT" -eq 0 ]]; then
  jq -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg diagnosis "$DIAGNOSIS" \
    --arg recipes "$RECIPES" \
    '{
      generatedAt: $ts,
      input: {diagnosis: $diagnosis, recipes: $recipes},
      summary: {planned: 0, applied: 0, passed: 0, failed: 0},
      actions: [],
      patchPath: null
    }' >"$OUTPUT"
  rm -f "$PLAN_FILE" "$RESULTS_FILE"
  exit 11
fi

mapfile -t ACTIONS < <(jq -c '.actions[]' "$PLAN_FILE")
for action in "${ACTIONS[@]}"; do
  id="$(echo "$action" | jq -r '.id')"
  cmd="$(echo "$action" | jq -r '.cmd')"
  max_attempts="$(echo "$action" | jq -r '.max_attempts // 1')"
  log_file="${LOG_DIR}/${id}.log"
  patch_file="${LOG_DIR}/${id}.patch"
  status="fail"
  last_exit=1
  attempts=0
  touched_json='[]'

  for ((i=1; i<=max_attempts; i++)); do
    attempts="$i"
    before="$(mktemp)"
    after="$(mktemp)"
    before_sorted="$(mktemp)"
    after_sorted="$(mktemp)"
    git diff --name-only >"$before"

    set +e
    bash -lc "$cmd" 2>&1 | tee "$log_file"
    rc=${PIPESTATUS[0]}
    set -e

    git diff --name-only >"$after"
    sort -u "$before" >"$before_sorted"
    sort -u "$after" >"$after_sorted"
    touched_json="$(comm -13 "$before_sorted" "$after_sorted" | jq -R -s 'split("\n") | map(select(length>0))')"

    rm -f "$before" "$after" "$before_sorted" "$after_sorted"
    last_exit="$rc"

    if [[ "$rc" -eq 0 ]]; then
      status="pass"
      break
    fi
  done

  if [[ "$(echo "$touched_json" | jq 'length')" -gt 0 ]]; then
    jq -r '.[]' <<<"$touched_json" | xargs git diff -- >"$patch_file" 2>/dev/null || true
  else
    : >"$patch_file"
  fi

  result="$(jq -n \
    --arg id "$id" \
    --arg check "$(echo "$action" | jq -r '.check // ""')" \
    --arg category "$(echo "$action" | jq -r '.category // ""')" \
    --arg mode "$(echo "$action" | jq -r '.mode // ""')" \
    --arg cmd "$cmd" \
    --arg status "$status" \
    --arg logPath "$log_file" \
    --arg patchPath "$patch_file" \
    --argjson attempts "$attempts" \
    --argjson exitCode "$last_exit" \
    --argjson touchedFiles "$touched_json" \
    '{id:$id,check:$check,category:$category,mode:$mode,cmd:$cmd,status:$status,attempts:$attempts,exitCode:$exitCode,logPath:$logPath,patchPath:$patchPath,touchedFiles:$touchedFiles}')"

  jq --argjson r "$result" '. + [$r]' "$RESULTS_FILE" >"${RESULTS_FILE}.next"
  mv "${RESULTS_FILE}.next" "$RESULTS_FILE"
done

FINAL_PATCH="${WORK_DIR}/repair.patch"
git diff >"$FINAL_PATCH" || true

jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg diagnosis "$DIAGNOSIS" \
  --arg recipes "$RECIPES" \
  --arg patchPath "$FINAL_PATCH" \
  --slurpfile actions "$RESULTS_FILE" \
  '{
    generatedAt: $ts,
    input: {diagnosis: $diagnosis, recipes: $recipes},
    summary: {
      planned: ($actions[0] | length),
      applied: ($actions[0] | length),
      passed: ($actions[0] | map(select(.status=="pass")) | length),
      failed: ($actions[0] | map(select(.status!="pass")) | length)
    },
    actions: $actions[0],
    patchPath: $patchPath
  }' >"$OUTPUT"

FAILED_COUNT="$(jq '.summary.failed' "$OUTPUT")"
rm -f "$PLAN_FILE" "$RESULTS_FILE"

if [[ "$FAILED_COUNT" -gt 0 ]]; then
  exit 12
fi
exit 0
