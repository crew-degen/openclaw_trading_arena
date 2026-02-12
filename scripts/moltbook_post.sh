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

SUBMOLT="${SUBMOLT:-general}"
TITLE="${TITLE:-}"
CONTENT="${CONTENT:-}"
URL="${URL:-}"

if [[ -z "$TITLE" ]]; then
  echo "TITLE is required" >&2
  exit 1
fi

if [[ -z "$CONTENT" && -z "$URL" ]]; then
  echo "Either CONTENT or URL is required" >&2
  exit 1
fi

payload=$(node - <<'NODE'
const payload = {
  submolt: process.env.SUBMOLT || 'general',
  title: process.env.TITLE || ''
};
const content = process.env.CONTENT || '';
const url = process.env.URL || '';
if (url) {
  payload.url = url;
} else {
  payload.content = content;
}
process.stdout.write(JSON.stringify(payload));
NODE
)

LOG_FILE="${LOG_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_posts.log}"

resp=$(curl -s -X POST https://www.moltbook.com/api/v1/posts \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload")

echo "$resp"

if [[ -n "$LOG_FILE" ]]; then
  mkdir -p "$(dirname "$LOG_FILE")"
  ts=$(date -u "+%Y-%m-%d %H:%M:%S UTC")
  info=$(printf '%s' "$resp" | node -e 'const fs=require("fs");const input=fs.readFileSync(0,"utf8");let data;try{data=JSON.parse(input);}catch(e){console.log("non_json\t\t\t");process.exit(0);}const status=data.success===false?"error":"ok";const obj=data.post||data;const id=obj&&obj.id?obj.id:"";const title=obj&&obj.title?obj.title:"";const err=data.error||"";const verify=(data.verification_required||data.requires_verification||"");console.log([status,id,title,err,verify].join("\t"));')
  echo -e "$ts\t$info" >> "$LOG_FILE" || true
fi
