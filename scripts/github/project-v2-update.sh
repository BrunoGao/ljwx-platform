#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=true
PROJECT_ID=""
ITEM_ID=""
FIELD_ID=""
OPTION_ID=""
VALUE_TEXT=""

usage() {
  cat <<USAGE
Usage: scripts/github/project-v2-update.sh [options]

Options:
  --dry-run                Print GraphQL command only (default)
  --apply                  Execute GraphQL mutation
  --project-id <id>        Project V2 node ID
  --item-id <id>           Project item node ID
  --field-id <id>          Field node ID
  --option-id <id>         Single-select option node ID (optional)
  --value-text <text>      Text value (optional)
USAGE
}

print_cmd() {
  printf '[dry-run] '
  printf '%q ' "$@"
  echo
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --apply)
      DRY_RUN=false
      shift
      ;;
    --project-id)
      PROJECT_ID="${2:?missing value for --project-id}"
      shift 2
      ;;
    --item-id)
      ITEM_ID="${2:?missing value for --item-id}"
      shift 2
      ;;
    --field-id)
      FIELD_ID="${2:?missing value for --field-id}"
      shift 2
      ;;
    --option-id)
      OPTION_ID="${2:?missing value for --option-id}"
      shift 2
      ;;
    --value-text)
      VALUE_TEXT="${2:?missing value for --value-text}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$PROJECT_ID" || -z "$ITEM_ID" || -z "$FIELD_ID" ]]; then
  echo "project-id, item-id, field-id are required" >&2
  exit 1
fi

if [[ -n "$OPTION_ID" && -n "$VALUE_TEXT" ]]; then
  echo "Use either --option-id or --value-text, not both" >&2
  exit 1
fi

if [[ -z "$OPTION_ID" && -z "$VALUE_TEXT" ]]; then
  echo "Either --option-id or --value-text is required" >&2
  exit 1
fi

if [[ -n "$OPTION_ID" ]]; then
  QUERY='mutation($project:ID!, $item:ID!, $field:ID!, $option:String!) { updateProjectV2ItemFieldValue(input:{projectId:$project,itemId:$item,fieldId:$field,value:{singleSelectOptionId:$option}}) { projectV2Item { id } } }'
  ARGS=(
    gh api graphql
    -f query="$QUERY"
    -f project="$PROJECT_ID"
    -f item="$ITEM_ID"
    -f field="$FIELD_ID"
    -f option="$OPTION_ID"
  )
else
  QUERY='mutation($project:ID!, $item:ID!, $field:ID!, $text:String!) { updateProjectV2ItemFieldValue(input:{projectId:$project,itemId:$item,fieldId:$field,value:{text:$text}}) { projectV2Item { id } } }'
  ARGS=(
    gh api graphql
    -f query="$QUERY"
    -f project="$PROJECT_ID"
    -f item="$ITEM_ID"
    -f field="$FIELD_ID"
    -f text="$VALUE_TEXT"
  )
fi

if [[ "$DRY_RUN" == "true" ]]; then
  print_cmd "${ARGS[@]}"
  echo "Dry-run mode: no Project V2 fields were changed."
else
  "${ARGS[@]}"
  echo "Project V2 field updated."
fi
