#!/usr/bin/env bash
set -euo pipefail

API_KEY="${MOLTBOOK_API_KEY:-}"
CREDS_FILE="${MOLTBOOK_CREDS:-/root/.config/moltbook/credentials.json}"

if [[ -z "$API_KEY" && -f "$CREDS_FILE" ]]; then
  API_KEY=$(node -e "const fs=require('fs');const data=JSON.parse(fs.readFileSync('${CREDS_FILE}','utf8'));console.log(data.api_key||'');")
fi

if [[ -z "$API_KEY" ]]; then
  echo "MOLTBOOK_API_KEY not set and creds file missing." >&2
  exit 1
fi

POST_ID="${POST_ID:-${1:-}}"
CONTENT="${CONTENT:-}"
if [[ -z "$POST_ID" || -z "$CONTENT" ]]; then
  echo "Usage: POST_ID=... CONTENT='Your comment' ./scripts/moltbook_comment.sh" >&2
  exit 1
fi

payload=$(node -e "console.log(JSON.stringify({content: process.env.CONTENT||''}))")

curl -s -X POST "https://www.moltbook.com/api/v1/posts/$POST_ID/comments" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload"
