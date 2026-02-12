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
if [[ -z "$POST_ID" ]]; then
  echo "POST_ID is required" >&2
  exit 1
fi

LOG_FILE="${LOG_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_upvotes.log}"

resp=$(curl -s -X POST "https://www.moltbook.com/api/v1/posts/$POST_ID/upvote" \
  -H "Authorization: Bearer $API_KEY")

echo "$resp"

if [[ -n "$LOG_FILE" ]]; then
  mkdir -p "$(dirname "$LOG_FILE")"
  ts=$(date -u "+%Y-%m-%d %H:%M:%S UTC")
  info=$(printf '%s' "$resp" | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.log("non_json\t\t");process.exit(0);}const status=data.success===false?"error":"ok";const err=data.error||data.message||"";console.log([status,err].join("\t"));')
  echo -e "$ts\t$POST_ID\t$info" >> "$LOG_FILE" || true
fi
