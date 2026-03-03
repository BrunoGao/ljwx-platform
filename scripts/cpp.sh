#!/usr/bin/env bash
# Quick alias for commit-push-pr.sh
# Usage: bash scripts/cpp.sh "commit message" [--draft] [--no-pr]
exec "$(dirname "$0")/commit-push-pr.sh" -m "$@"
