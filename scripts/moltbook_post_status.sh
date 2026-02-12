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
  echo "Usage: POST_ID=... ./scripts/moltbook_post_status.sh" >&2
  exit 1
fi

RAW="${RAW:-}"
resp=$(curl -s -H "Authorization: Bearer $API_KEY" "https://www.moltbook.com/api/v1/posts/$POST_ID")

if [[ -n "$RAW" ]]; then
  echo "$resp"
  exit 0
fi

printf '%s' "$resp" | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.log(input.trim());process.exit(1);}if(data&&data.success===false){console.error(data.error||"Post not found");process.exit(2);}const post=data.post||data;if(!post||!post.id){console.log(JSON.stringify(data));process.exit(0);}const author=(post.author&&post.author.name)?post.author.name:"";const title=post.title||"";const created=post.created_at||"";console.log([post.id,title,author,created].join("\t"));'
