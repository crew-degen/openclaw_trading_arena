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

AUTH_MODE="${AUTH_MODE:-bearer}" # bearer | x-api-key
TRY_X_API_KEY="${TRY_X_API_KEY:-1}"
LIMIT="${LIMIT:-50}"
SORT="${SORT:-new}"

endpoints=(
  "/api/v1/me/posts"
  "/api/v1/users/me/posts"
  "/api/v1/posts/me"
  "/api/v1/me/posts?sort=${SORT}&limit=${LIMIT}"
  "/api/v1/users/me/posts?sort=${SORT}&limit=${LIMIT}"
  "/api/v1/posts?mine=true&sort=${SORT}&limit=${LIMIT}"
  "/api/v1/posts?author=me&sort=${SORT}&limit=${LIMIT}"
)

header() {
  if [[ "$AUTH_MODE" == "x-api-key" ]]; then
    echo "X-API-Key: $API_KEY"
  else
    echo "Authorization: Bearer $API_KEY"
  fi
}

try_endpoint() {
  local url="$1"
  local resp
  resp=$(curl -s -H "$(header)" "https://www.moltbook.com${url}")
  # validate JSON
  if echo "$resp" | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");try{JSON.parse(input);process.exit(0);}catch(e){process.exit(1);}'; then
    echo "$url"
    echo "$resp"
    return 0
  fi
  return 1
}

for ep in "${endpoints[@]}"; do
  if out=$(try_endpoint "$ep"); then
    echo "ENDPOINT\t$ep" >&2
    echo "$out" | tail -n +2 | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");const data=JSON.parse(input);const posts=Array.isArray(data)?data:(data.posts||[]);for(const p of posts){const author=p.author&&p.author.name?p.author.name:"";console.log([p.id,p.title||"",author,p.created_at||""].join("\t"));}console.log(`-- count: ${posts.length}`);'
    exit 0
  fi
  # retry with x-api-key if enabled
  if [[ "$TRY_X_API_KEY" == "1" && "$AUTH_MODE" != "x-api-key" ]]; then
    AUTH_MODE="x-api-key"
    if out=$(try_endpoint "$ep"); then
      echo "ENDPOINT\t$ep (x-api-key)" >&2
      echo "$out" | tail -n +2 | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");const data=JSON.parse(input);const posts=Array.isArray(data)?data:(data.posts||[]);for(const p of posts){const author=p.author&&p.author.name?p.author.name:"";console.log([p.id,p.title||"",author,p.created_at||""].join("\t"));}console.log(`-- count: ${posts.length}`);'
      exit 0
    fi
    AUTH_MODE="bearer"
  fi
 done

echo "No JSON response from candidate endpoints." >&2
exit 2
