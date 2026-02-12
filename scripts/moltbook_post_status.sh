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
SCAN_FEED="${SCAN_FEED:-}"
SCAN_LIMIT="${SCAN_LIMIT:-100}"
SCAN_PAGES="${SCAN_PAGES:-5}"
resp=$(curl -s -H "Authorization: Bearer $API_KEY" "https://www.moltbook.com/api/v1/posts/$POST_ID")

if [[ -n "$RAW" ]]; then
  echo "$resp"
  exit 0
fi

if [[ -n "$SCAN_FEED" ]] && echo "$resp" | grep -q '"success":false' && echo "$resp" | grep -q 'Post not found'; then
  offset=0
  page=1
  while [[ $page -le $SCAN_PAGES ]]; do
    feed=$(curl -s -H "Authorization: Bearer $API_KEY" "https://www.moltbook.com/api/v1/posts?sort=new&limit=$SCAN_LIMIT&offset=$offset")
    result=$(printf '%s' "$feed" | POST_ID="$POST_ID" node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.error("Invalid JSON from feed");process.exit(1);}const posts=Array.isArray(data)?data:(data.posts||[]);const id=process.env.POST_ID;const match=posts.find(p=>p.id===id);if(match){const author=(match.author&&match.author.name)?match.author.name:"";const title=match.title||"";const created=match.created_at||"";console.log(["FOUND",match.id,title,author,created].join("\t"));}else{console.log(["MISS",String(!!data.has_more),String(data.next_offset??""),String(posts.length)].join("\t"));}')
    if echo "$result" | grep -q '^FOUND'; then
      echo "$result" | cut -f2-
      exit 0
    fi
    has_more=$(echo "$result" | awk -F'\t' '{print $2}')
    next_offset=$(echo "$result" | awk -F'\t' '{print $3}')
    count=$(echo "$result" | awk -F'\t' '{print $4}')
    if [[ "$has_more" != "true" ]]; then
      echo "Post not found in feed (pages=$page, last_count=$count)" >&2
      exit 3
    fi
    if [[ -z "$next_offset" ]]; then
      offset=$((offset + SCAN_LIMIT))
    else
      offset="$next_offset"
    fi
    page=$((page + 1))
  done
  echo "Post not found in feed (pages=$SCAN_PAGES, limit=$SCAN_LIMIT)" >&2
  exit 3
fi

printf '%s' "$resp" | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.log(input.trim());process.exit(1);}if(data&&data.success===false){console.error(data.error||"Post not found");process.exit(2);}const post=data.post||data;if(!post||!post.id){console.log(JSON.stringify(data));process.exit(0);}const author=(post.author&&post.author.name)?post.author.name:"";const title=post.title||"";const created=post.created_at||"";console.log([post.id,title,author,created].join("\t"));'
