#!/usr/bin/env bash
set -euo pipefail

INPUT_URL="${POST_URL:-${1:-}}"
if [[ -z "$INPUT_URL" ]]; then
  echo "Usage: POST_URL=<url|id> ./scripts/moltbook_post_status_by_url.sh" >&2
  exit 1
fi

# If input is already a UUID, use it directly
if echo "$INPUT_URL" | grep -Eq '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
  POST_ID="$INPUT_URL"
else
  POST_ID=$(echo "$INPUT_URL" | grep -Eo '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | head -n1 || true)
fi

if [[ -z "$POST_ID" ]]; then
  echo "Could not extract post id from: $INPUT_URL" >&2
  exit 1
fi

POST_ID="$POST_ID" \
  SCAN_FEED="${SCAN_FEED:-}" \
  SCAN_ENDPOINT="${SCAN_ENDPOINT:-}" \
  SCAN_LIMIT="${SCAN_LIMIT:-}" \
  SCAN_PAGES="${SCAN_PAGES:-}" \
  FORCE_PAGES="${FORCE_PAGES:-}" \
  SCAN_OFFSET="${SCAN_OFFSET:-}" \
  SCAN_STEP="${SCAN_STEP:-}" \
  /root/projects/openclaw_trading_arena/scripts/moltbook_post_status.sh
