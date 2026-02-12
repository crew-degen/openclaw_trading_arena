#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_posts.log}"
PENDING_FILE="${PENDING_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_pending_ids.txt}"
LIMIT="${LIMIT:-10}"

if [[ ! -f "$LOG_FILE" && ! -f "$PENDING_FILE" ]]; then
  echo "No log or pending file found." >&2
  exit 1
fi

if [[ ! -f "$LOG_FILE" && -f "$PENDING_FILE" ]]; then
  ids=$(tail -n "$LIMIT" "$PENDING_FILE" | awk -F'\t' '{print $1}')
else
  ids=$(node -e 'const fs=require("fs");const file=process.argv[1];const limit=parseInt(process.env.LIMIT||"10",10);const raw=fs.readFileSync(file,"utf8").trim();if(!raw){process.exit(0);}const lines=raw.split(/\n+/).reverse();const out=[];const seen=new Set();for(const line of lines){const cols=line.split("\t");const id=(cols[2]||"").trim();const err=(cols[4]||"");const verify=(cols[5]||"");const needs=verify || /verify/i.test(err) || /verification/i.test(err);if(!id || !needs || seen.has(id)) continue;seen.add(id);out.push(id);if(out.length>=limit) break;}console.log(out.join("\n"));' "$LOG_FILE")
fi

if [[ -z "$ids" ]]; then
  echo "No pending posts found in log." >&2
  exit 0
fi

count=0
while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  echo "== $id"
  /root/projects/openclaw_trading_arena/scripts/moltbook_post_check.sh "$id" || true
  echo
  count=$((count + 1))
  if [[ $count -ge $LIMIT ]]; then
    break
  fi
  sleep 0.2
done <<< "$ids"
