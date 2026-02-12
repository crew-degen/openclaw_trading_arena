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
CONTENT_FILE="${CONTENT_FILE:-}"
CONTENT_B64="${CONTENT_B64:-}"
if [[ -n "$CONTENT_FILE" ]]; then
  if [[ ! -f "$CONTENT_FILE" ]]; then
    echo "CONTENT_FILE not found: $CONTENT_FILE" >&2
    exit 1
  fi
  CONTENT=$(cat "$CONTENT_FILE")
elif [[ -n "$CONTENT_B64" ]]; then
  CONTENT=$(printf '%s' "$CONTENT_B64" | base64 -d)
fi

if [[ -z "$POST_ID" || -z "$CONTENT" ]]; then
  echo "Usage: POST_ID=... CONTENT='Your comment' ./scripts/moltbook_comment.sh" >&2
  echo "Or:   POST_ID=... CONTENT_FILE=path.txt ./scripts/moltbook_comment.sh" >&2
  echo "Or:   POST_ID=... CONTENT_B64=... ./scripts/moltbook_comment.sh" >&2
  exit 1
fi

payload=$(CONTENT="$CONTENT" node -e "console.log(JSON.stringify({content: process.env.CONTENT||''}))")

LOG_FILE="${LOG_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_comments.log}"

resp=$(curl -s -X POST "https://www.moltbook.com/api/v1/posts/$POST_ID/comments" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload")

echo "$resp"

if [[ -n "$LOG_FILE" ]]; then
  mkdir -p "$(dirname "$LOG_FILE")"
  ts=$(date -u "+%Y-%m-%d %H:%M:%S UTC")
  info=$(printf '%s' "$resp" | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.log("non_json\t\t\t");process.exit(0);}const status=data.success===false?"error":"ok";const comment=data.comment||data;const id=comment&&comment.id?comment.id:"";const err=data.error||data.message||"";const verify=(data.verification_required||data.requires_verification||"");console.log([status,id,err,verify].join("\t"));')
  echo -e "$ts\t$POST_ID\t$info" >> "$LOG_FILE" || true
fi
