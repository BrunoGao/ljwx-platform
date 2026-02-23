#!/usr/bin/env bash
# PreToolUse hook: path-level guard only.
# Checks file_path from stdin JSON. No content parsing.
# Exit 2 = block the tool call.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r ".tool_input.file_path // empty" 2>/dev/null || true)
[[ -z "$FILE_PATH" ]] && exit 0

# Rule: Flyway migration must be in the correct directory
if [[ "$FILE_PATH" =~ \.sql$ ]] && [[ "$FILE_PATH" =~ migration ]]; then
  if echo "$FILE_PATH" | grep -q "^ljwx-platform-app/src/main/resources/db/migration/"; then
    : # correct path
  else
    echo "BLOCKED: SQL migration must be in ljwx-platform-app/src/main/resources/db/migration/" >&2
    echo "         Got: $FILE_PATH" >&2
    exit 2
  fi
fi

# Rule: data module must not reference security
if [[ "$FILE_PATH" =~ ^ljwx-platform-data/ ]]; then
  if echo "$FILE_PATH" | grep -qi security; then
    echo "BLOCKED: data module must not reference security (DAG violation)" >&2
    exit 2
  fi
fi

# Rule: security module must not contain web-layer code
if [[ "$FILE_PATH" =~ ^ljwx-platform-security/ ]]; then
  if [[ "$FILE_PATH" =~ /web/ ]]; then
    echo "BLOCKED: security module must not contain web-layer code (DAG violation)" >&2
    exit 2
  fi
fi

# Rule: deny direct edits to .env secret files (.env.example is a template and is allowed)
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  .env.example)
    : # template file — allowed
    ;;
  .env|.env.*)
    echo "BLOCKED: Direct edit of .env secret files not allowed." >&2
    exit 2
    ;;
esac

exit 0
