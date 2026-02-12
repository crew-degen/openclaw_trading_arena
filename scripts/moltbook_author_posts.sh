#!/usr/bin/env bash
set -euo pipefail

API_KEY="${MOLTBOOK_API_KEY:-}"
CREDS_FILE="${MOLTBOOK_CREDS:-/root/.config/moltbook/credentials.json}"
DEFAULT_AUTHOR=""

if [[ -f "$CREDS_FILE" ]]; then
  DEFAULT_AUTHOR=$(node -e "const fs=require('fs');const data=JSON.parse(fs.readFileSync('${CREDS_FILE}','utf8'));console.log(data.agent_name||'');")
fi

if [[ -z "$API_KEY" && -f "$CREDS_FILE" ]]; then
  API_KEY=$(node -e "const fs=require('fs');const data=JSON.parse(fs.readFileSync('${CREDS_FILE}','utf8'));console.log(data.api_key||'');")
fi

if [[ -z "$API_KEY" ]]; then
  echo "MOLTBOOK_API_KEY not set and creds file missing." >&2
  exit 1
fi

AUTHOR_NAME="${AUTHOR_NAME:-$DEFAULT_AUTHOR}"
AUTHOR_ID="${AUTHOR_ID:-}"
if [[ -z "$AUTHOR_NAME" && -z "$AUTHOR_ID" ]]; then
  echo "Set AUTHOR_NAME or AUTHOR_ID (default from creds if available)." >&2
  exit 1
fi

SORT="${SORT:-new}"
LIMIT="${LIMIT:-100}"
PAGES="${PAGES:-5}"
SCAN_OFFSET="${SCAN_OFFSET:-0}"
SCAN_STEP="${SCAN_STEP:-$LIMIT}"
OFFSET="$SCAN_OFFSET"
FORCE_PAGES="${FORCE_PAGES:-1}"
SCAN_ENDPOINT="${SCAN_ENDPOINT:-posts}" # posts | feed

page=1
total_matches=0

while [[ $page -le $PAGES ]]; do
  if [[ "$SCAN_ENDPOINT" == "feed" ]]; then
    url="https://www.moltbook.com/api/v1/feed?sort=${SORT}&limit=${LIMIT}&offset=${OFFSET}"
  else
    url="https://www.moltbook.com/api/v1/posts?sort=${SORT}&limit=${LIMIT}&offset=${OFFSET}"
  fi
  feed=$(curl -s -H "Authorization: Bearer $API_KEY" "$url")
  result=$(printf '%s' "$feed" | AUTHOR_NAME="$AUTHOR_NAME" AUTHOR_ID="$AUTHOR_ID" node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.error("Invalid JSON from feed");process.exit(1);}const posts=Array.isArray(data)?data:(data.posts||[]);const name=(process.env.AUTHOR_NAME||"").toLowerCase();const id=process.env.AUTHOR_ID||"";const matches=posts.filter(p=>{const aid=p.author&&p.author.id?String(p.author.id):"";const aname=p.author&&p.author.name?p.author.name.toLowerCase():"";if(id && aid===id) return true; if(name && aname===name) return true; return false;});for(const m of matches){const author=(m.author&&m.author.name)||"";const title=m.title||"";const created=m.created_at||"";console.log([m.id,title,author,created].join("\t"));}const hasMore = data && typeof data.has_more !== "undefined" ? !!data.has_more : null;const nextOffset = data && typeof data.next_offset !== "undefined" ? data.next_offset : null;console.log(["META",String(hasMore),String(nextOffset??""),String(posts.length),String(matches.length)].join("\t"));')

  meta=$(echo "$result" | tail -n1)
  matches=$(echo "$result" | sed '$d')
  if [[ -n "$matches" ]]; then
    echo "$matches"
  fi

  has_more=$(echo "$meta" | awk -F'\t' '{print $2}')
  next_offset=$(echo "$meta" | awk -F'\t' '{print $3}')
  count=$(echo "$meta" | awk -F'\t' '{print $4}')
  match_count=$(echo "$meta" | awk -F'\t' '{print $5}')
  total_matches=$((total_matches + match_count))

  if [[ "$SCAN_ENDPOINT" != "feed" && "$has_more" != "true" && "$FORCE_PAGES" != "1" ]]; then
    break
  fi

  if [[ -n "$next_offset" ]]; then
    OFFSET="$next_offset"
  else
    OFFSET=$((OFFSET + SCAN_STEP))
  fi

  if [[ "$count" == "0" ]]; then
    break
  fi

  if [[ "$SCAN_ENDPOINT" == "feed" && "$FORCE_PAGES" != "1" ]]; then
    break
  fi

  page=$((page + 1))
  sleep 0.2
 done

echo "-- matches: $total_matches (pages=$PAGES, limit=$LIMIT)" >&2
