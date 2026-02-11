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

SORT="${SORT:-new}"
LIMIT="${LIMIT:-10}"
SUBMOLT="${SUBMOLT:-}"

if [[ -n "$SUBMOLT" ]]; then
  URL="https://www.moltbook.com/api/v1/posts?submolt=${SUBMOLT}&sort=${SORT}&limit=${LIMIT}"
else
  URL="https://www.moltbook.com/api/v1/feed?sort=${SORT}&limit=${LIMIT}"
fi

curl -s -H "Authorization: Bearer $API_KEY" "$URL" | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.error("Invalid JSON from Moltbook");process.exit(1);}const posts=Array.isArray(data)?data:(data.posts||[]);for(const p of posts){const pid=p.id;const title=p.title||"";const author=(p.author&&p.author.name)||p.authorName||"";const submoltObj=p.submolt||"";const submolt=(submoltObj&&typeof submoltObj==="object")?(submoltObj.name||submoltObj.slug||""):submoltObj;console.log(pid+"\t"+submolt+"\t"+author+"\t"+title);}';
