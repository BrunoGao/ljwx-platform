#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE_FILE="${PROJECT_ROOT}/.github/projectv2/project.json"

info() { printf '[info] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
die() { printf '[error] %s\n' "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

trim() {
  local s="$*"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

upper() {
  printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

ensure_tools() {
  need_cmd gh
  need_cmd jq
}

remote_owner_repo() {
  local remote
  remote="$(git -C "$PROJECT_ROOT" config --get remote.origin.url 2>/dev/null || true)"
  if [[ "$remote" =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    printf '%s\n%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

resolve_repo() {
  local owner="" repo=""
  if mapfile -t rr < <(remote_owner_repo); then
    owner="${rr[0]}"
    repo="${rr[1]}"
  fi
  if [[ -z "$owner" || -z "$repo" ]]; then
    owner="${GITHUB_REPOSITORY_OWNER:-}"
    repo="${GITHUB_REPOSITORY#*/}"
  fi
  [[ -n "$owner" && -n "$repo" ]] || die "cannot resolve owner/repo from git remote or env"
  printf '%s\n%s\n' "$owner" "$repo"
}

project_id_from_cache() {
  [[ -f "$CACHE_FILE" ]] || return 1
  jq -r '.projectId // empty' "$CACHE_FILE"
}

resolve_project_id_from_url() {
  local url="$1"
  local owner scope number query id
  if [[ "$url" =~ github.com/orgs/([^/]+)/projects/([0-9]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    number="${BASH_REMATCH[2]}"
    scope="organization"
  elif [[ "$url" =~ github.com/users/([^/]+)/projects/([0-9]+) ]]; then
    owner="${BASH_REMATCH[1]}"
    number="${BASH_REMATCH[2]}"
    scope="user"
  else
    die "unsupported project url: $url"
  fi

  if [[ "$scope" == "organization" ]]; then
    query='query($owner:String!, $number:Int!){ organization(login:$owner){ projectV2(number:$number){ id title url } } }'
    id="$(gh api graphql -f query="$query" -F owner="$owner" -F number="$number" | jq -r '.data.organization.projectV2.id // empty')"
  else
    query='query($owner:String!, $number:Int!){ user(login:$owner){ projectV2(number:$number){ id title url } } }'
    id="$(gh api graphql -f query="$query" -F owner="$owner" -F number="$number" | jq -r '.data.user.projectV2.id // empty')"
  fi
  [[ -n "$id" ]] || die "cannot resolve project node id from url: $url"
  printf '%s' "$id"
}

issue_number_from_url() {
  local url="$1"
  if [[ "$url" =~ github.com/([^/]+)/([^/]+)/issues/([0-9]+) ]]; then
    printf '%s\n%s\n%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    return 0
  fi
  return 1
}

query_issue_data() {
  local owner="$1" repo="$2" number="$3"
  local q
  q='query($owner:String!, $repo:String!, $number:Int!){ repository(owner:$owner,name:$repo){ issue(number:$number){ id number title body labels(first:50){nodes{name}} url } } }'
  gh api graphql -f query="$q" -F owner="$owner" -F repo="$repo" -F number="$number"
}

find_project_item_for_issue() {
  local project_id="$1" issue_node_id="$2"
  local q
  q='query($project:ID!){ node(id:$project){ ... on ProjectV2 { items(first:200){ nodes { id content { __typename ... on Issue { id number } } } } } } }'
  gh api graphql -f query="$q" -F project="$project_id" \
    | jq -r --arg iid "$issue_node_id" '.data.node.items.nodes[] | select(.content.id == $iid) | .id' \
    | head -n1
}

option_id_from_cache() {
  local field_key="$1" option_name="$2"
  [[ -f "$CACHE_FILE" ]] || return 1
  local fk
  fk="$(normalize_field_key "$field_key")"
  jq -r --arg fk "$fk" --arg opt "$option_name" '
    .options[$fk][$opt]
    // .fields[$fk].options[$opt]
    // empty
  ' "$CACHE_FILE"
}

normalize_field_key() {
  local s
  s="$(lower "$(trim "$1")")"
  s="${s// /}"
  s="${s//_/}"
  s="${s//-/}"
  case "$s" in
    phase) echo "Phase" ;;
    workflow) echo "Workflow" ;;
    priority) echo "Priority" ;;
    gatestatus|gate) echo "GateStatus" ;;
    workstream) echo "Workstream" ;;
    suite) echo "Suite" ;;
    *) echo "$1" ;;
  esac
}

field_id_from_cache() {
  local key="$1"
  [[ -f "$CACHE_FILE" ]] || return 1
  local fk
  fk="$(normalize_field_key "$key")"
  case "$fk" in
    Phase) jq -r '.fields.Phase.id // .fields.phase.id // empty' "$CACHE_FILE" ;;
    Workflow) jq -r '.fields.Workflow.id // .fields.workflow.id // empty' "$CACHE_FILE" ;;
    Priority) jq -r '.fields.Priority.id // .fields.priority.id // empty' "$CACHE_FILE" ;;
    GateStatus) jq -r '.fields.GateStatus.id // .fields.gate_status.id // .fields.gatestatus.id // empty' "$CACHE_FILE" ;;
    Workstream) jq -r '.fields.Workstream.id // .fields.workstream.id // empty' "$CACHE_FILE" ;;
    Suite) jq -r '.fields.Suite.id // .fields.suite.id // empty' "$CACHE_FILE" ;;
    *) jq -r --arg key "$fk" '.fields[$key].id // empty' "$CACHE_FILE" ;;
  esac
}

extract_body_field_value() {
  local body="$1" name="$2"
  awk -v n="$name" '
    BEGIN { IGNORECASE = 1 }
    $0 ~ "^[[:space:]]*" n "[[:space:]]*:[[:space:]]*" {
      sub("^[[:space:]]*" n "[[:space:]]*:[[:space:]]*", "", $0)
      print $0
      exit
    }
  ' <<<"$body" | sed 's/[[:space:]]*$//'
}
