#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/project/_lib.sh
source "$SCRIPT_DIR/_lib.sh"

DRY_RUN=true
PROJECT_ID=""
PROJECT_URL=""

usage() {
  cat <<USAGE
Usage: scripts/project/project-bootstrap.sh [options]

Options:
  --project-id <PVT_...>         Project V2 node ID
  --project-url <url>            Project URL (org/user projects/<number>)
  --dry-run                      Print summary only (default)
  --apply                        Write .github/projectv2/project.json
  -h, --help                     Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id) PROJECT_ID="${2:?missing value for --project-id}"; shift 2 ;;
    --project-url) PROJECT_URL="${2:?missing value for --project-url}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --apply) DRY_RUN=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

ensure_tools

if [[ -z "$PROJECT_ID" && -z "$PROJECT_URL" ]]; then
  die "either --project-id or --project-url is required"
fi

if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID="$(resolve_project_id_from_url "$PROJECT_URL")"
fi

q='query($project:ID!){
  node(id:$project){
    __typename
    ... on ProjectV2 {
      id
      title
      url
      fields(first:100){
        nodes{
          __typename
          ... on ProjectV2FieldCommon {
            id
            name
            dataType
          }
          ... on ProjectV2SingleSelectField {
            options { id name }
          }
        }
      }
    }
  }
}'

raw="$(gh api graphql -f query="$q" -F project="$PROJECT_ID")"
ptype="$(jq -r '.data.node.__typename // empty' <<<"$raw")"
[[ "$ptype" == "ProjectV2" ]] || die "node is not ProjectV2: ${ptype:-unknown}"

owner="unknown"
repo="unknown"
if mapfile -t rr < <(resolve_repo); then
  owner="${rr[0]}"
  repo="${rr[1]}"
fi

cache_json="$(jq -n \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg owner "$owner" \
  --arg repo "$repo" \
  --arg projectId "$PROJECT_ID" \
  --argjson project "$(jq '.data.node' <<<"$raw")" \
  '
  def keyname($n): ($n|ascii_downcase|gsub("[^a-z0-9]+";"_")|gsub("(^_|_$)";""));
  {
    generated_at:$generated_at,
    repo:{owner:$owner,name:$repo},
    projectId:$projectId,
    projectTitle:($project.title // ""),
    projectUrl:($project.url // ""),
    fields:(
      reduce ($project.fields.nodes // [])[] as $f ({};
        . + {
          (keyname($f.name)):{
            id:$f.id,
            name:$f.name,
            dataType:$f.dataType,
            type:$f.__typename,
            options:(
              if $f.__typename == "ProjectV2SingleSelectField" then
                reduce ($f.options // [])[] as $o ({}; . + {($o.name):$o.id})
              else {}
              end
            )
          }
        }
      )
    ),
    all_fields:($project.fields.nodes // [])
  }
')"

printf 'Project: %s (%s)\n' "$(jq -r '.projectTitle' <<<"$cache_json")" "$PROJECT_ID"
printf 'URL: %s\n' "$(jq -r '.projectUrl' <<<"$cache_json")"
printf 'Fields:\n'
jq -r '.fields | to_entries[] | "- " + .value.name + " => " + .value.id + (if (.value.options|length)>0 then " (options: " + ((.value.options|keys)|join(",")) + ")" else "" end)' <<<"$cache_json"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] cache file not written: $CACHE_FILE"
else
  mkdir -p "$(dirname "$CACHE_FILE")"
  printf '%s\n' "$cache_json" > "$CACHE_FILE"
  echo "wrote cache: $CACHE_FILE"
fi
