#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_posts.log}"
MAX_POSTS="${MAX_POSTS:-20}"
SCAN_FEED="${SCAN_FEED:-1}"
SCAN_ENDPOINT="${SCAN_ENDPOINT:-posts}" # posts | feed
SCAN_LIMIT="${SCAN_LIMIT:-100}"
SCAN_PAGES="${SCAN_PAGES:-3}"
FORCE_PAGES="${FORCE_PAGES:-1}"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Log file not found: $LOG_FILE" >&2
  exit 1
fi

ids=$(node -e 'const fs=require("fs");const file=process.argv[1];const max=parseInt(process.env.MAX_POSTS||"20",10);const lines=fs.readFileSync(file,"utf8").trim().split(/\n+/);const seen=new Set();const out=[];for(let i=lines.length-1;i>=0;i--){const cols=lines[i].split("\t");const id=(cols[2]||"").trim();if(!id||seen.has(id)) continue;seen.add(id);out.push(id);if(out.length>=max) break;}console.log(out.join("\n"));' "$LOG_FILE")

if [[ -z "$ids" ]]; then
  echo "No post ids found in log." >&2
  exit 0
fi

count=0
while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  count=$((count + 1))
  echo "== $id"
  POST_ID="$id" SCAN_FEED="$SCAN_FEED" SCAN_ENDPOINT="$SCAN_ENDPOINT" SCAN_LIMIT="$SCAN_LIMIT" SCAN_PAGES="$SCAN_PAGES" FORCE_PAGES="$FORCE_PAGES" \
    /root/projects/openclaw_trading_arena/scripts/moltbook_post_status.sh || echo "NOT_FOUND\t$id"
  echo
  sleep 0.2
  if [[ $count -ge $MAX_POSTS ]]; then
    break
  fi
done <<< "$ids"
