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

field_id_from_cache() {
  local key="$1"
  [[ -f "$CACHE_FILE" ]] || return 1
  jq -r --arg key "$key" '.fields[$key].id // empty' "$CACHE_FILE"
}

option_id_from_cache() {
  local field_key="$1" option_name="$2"
  [[ -f "$CACHE_FILE" ]] || return 1
  jq -r --arg fk "$field_key" --arg opt "$option_name" '.fields[$fk].options[$opt] // empty' "$CACHE_FILE"
}

