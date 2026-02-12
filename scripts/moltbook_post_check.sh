#!/usr/bin/env bash
set -euo pipefail

INPUT="${POST_URL:-${POST_ID:-${1:-}}}"
if [[ -z "$INPUT" ]]; then
  echo "Usage: POST_URL=<url|id> ./scripts/moltbook_post_check.sh" >&2
  exit 1
fi

if echo "$INPUT" | grep -Eq '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
  POST_ID="$INPUT"
else
  POST_ID=$(echo "$INPUT" | grep -Eo '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | head -n1 || true)
fi

if [[ -z "$POST_ID" ]]; then
  echo "Could not extract post id from: $INPUT" >&2
  exit 1
fi

api_out=$(POST_ID="$POST_ID" TRY_X_API_KEY=1 TRY_QUERY=1 /root/projects/openclaw_trading_arena/scripts/moltbook_post_status.sh 2>&1 || true)
api_code=$?

page_out=$(POST_ID="$POST_ID" /root/projects/openclaw_trading_arena/scripts/moltbook_page_status.sh 2>&1 || true)
page_code=$?

if [[ $api_code -eq 0 ]]; then
  echo "API_FOUND\t$api_out"
else
  echo "API_NOT_FOUND\t$api_out"
fi

if [[ $page_code -eq 0 ]]; then
  echo "PAGE_FOUND\t$page_out"
else
  echo "PAGE_NOT_FOUND\t$page_out"
fi

if [[ $api_code -eq 0 || $page_code -eq 0 ]]; then
  exit 0
fi

exit 2
