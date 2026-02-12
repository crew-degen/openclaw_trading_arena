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
REQUIRE_NONEMPTY="${REQUIRE_NONEMPTY:-1}"
AUTHOR_NAME="${AUTHOR_NAME:-}"
AUTHOR_ID="${AUTHOR_ID:-}"

if [[ -z "$AUTHOR_NAME" && -f "$CREDS_FILE" ]]; then
  AUTHOR_NAME=$(node -e "const fs=require('fs');const data=JSON.parse(fs.readFileSync('${CREDS_FILE}','utf8'));console.log(data.agent_name||'');")
fi

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

last_output=""
last_endpoint=""
for ep in "${endpoints[@]}"; do
  if out=$(try_endpoint "$ep"); then
    processed=$(echo "$out" | tail -n +2 | AUTHOR_NAME="$AUTHOR_NAME" AUTHOR_ID="$AUTHOR_ID" node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");const data=JSON.parse(input);const posts=Array.isArray(data)?data:(data.posts||[]);const name=(process.env.AUTHOR_NAME||"").toLowerCase();const id=process.env.AUTHOR_ID||"";let matchCount=0;for(const p of posts){const authorName=(p.author&&p.author.name?p.author.name:"").toLowerCase();const authorId=(p.author&&p.author.id?p.author.id:"");const isMatch=(id && authorId===id) || (name && authorName===name);if(isMatch){matchCount++;console.log([p.id,p.title||"",p.author&&p.author.name?p.author.name:"",p.created_at||""].join("\t"));}}
console.log(["META",String(posts.length),String(matchCount)].join("\t"));')
    meta=$(echo "$processed" | tail -n1)
    matches=$(echo "$processed" | sed '$d')
    total_count=$(echo "$meta" | awk -F'\t' '{print $2}')
    match_count=$(echo "$meta" | awk -F'\t' '{print $3}')
    if [[ "$REQUIRE_NONEMPTY" != "1" || "$match_count" != "0" ]]; then
      echo "ENDPOINT\t$ep" >&2
      if [[ -n "$matches" ]]; then
        echo "$matches"
      fi
      echo "-- count: $total_count (matches: $match_count)"
      exit 0
    fi
    last_output="$processed"
    last_endpoint="$ep"
  fi
  # retry with x-api-key if enabled
  if [[ "$TRY_X_API_KEY" == "1" && "$AUTH_MODE" != "x-api-key" ]]; then
    AUTH_MODE="x-api-key"
    if out=$(try_endpoint "$ep"); then
      processed=$(echo "$out" | tail -n +2 | AUTHOR_NAME="$AUTHOR_NAME" AUTHOR_ID="$AUTHOR_ID" node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");const data=JSON.parse(input);const posts=Array.isArray(data)?data:(data.posts||[]);const name=(process.env.AUTHOR_NAME||"").toLowerCase();const id=process.env.AUTHOR_ID||"";let matchCount=0;for(const p of posts){const authorName=(p.author&&p.author.name?p.author.name:"").toLowerCase();const authorId=(p.author&&p.author.id?p.author.id:"");const isMatch=(id && authorId===id) || (name && authorName===name);if(isMatch){matchCount++;console.log([p.id,p.title||"",p.author&&p.author.name?p.author.name:"",p.created_at||""].join("\t"));}}
console.log(["META",String(posts.length),String(matchCount)].join("\t"));')
      meta=$(echo "$processed" | tail -n1)
      matches=$(echo "$processed" | sed '$d')
      total_count=$(echo "$meta" | awk -F'\t' '{print $2}')
      match_count=$(echo "$meta" | awk -F'\t' '{print $3}')
      if [[ "$REQUIRE_NONEMPTY" != "1" || "$match_count" != "0" ]]; then
        echo "ENDPOINT\t$ep (x-api-key)" >&2
        if [[ -n "$matches" ]]; then
          echo "$matches"
        fi
        echo "-- count: $total_count (matches: $match_count)"
        exit 0
      fi
      last_output="$processed"
      last_endpoint="$ep (x-api-key)"
    fi
    AUTH_MODE="bearer"
  fi
 done

if [[ -n "$last_output" ]]; then
  echo "ENDPOINT\t$last_endpoint" >&2
  matches=$(echo "$last_output" | sed '$d')
  meta=$(echo "$last_output" | tail -n1)
  total_count=$(echo "$meta" | awk -F'\t' '{print $2}')
  match_count=$(echo "$meta" | awk -F'\t' '{print $3}')
  if [[ -n "$matches" ]]; then
    echo "$matches"
  fi
  echo "-- count: $total_count (matches: $match_count)"
  exit 0
fi

echo "No JSON response from candidate endpoints." >&2
exit 2
