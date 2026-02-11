#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
PROGRESS="$ROOT_DIR/PROGRESS.md"
HACKATHON_ENV="/root/projects/hackathon/colosseum.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi
if [[ -f "$HACKATHON_ENV" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$HACKATHON_ENV"
  set +a
fi

API_KEY="${COLOSSEUM_API_KEY:-${AGENTS_API_KEY:-}}"
NOW="$(date -u '+%Y-%m-%d %H:%M UTC')"

HB_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://colosseum.com/heartbeat.md || echo "000")

HAS_POLL="unknown"
STATUS_CODE="000"
if [[ -n "$API_KEY" ]]; then
  STATUS_JSON=$(curl -s -w "\nHTTP:%{http_code}\n" -H "Authorization: Bearer $API_KEY" https://agents.colosseum.com/api/agents/status || true)
  STATUS_CODE=$(echo "$STATUS_JSON" | tail -n1 | sed 's/HTTP://')
  BODY=$(echo "$STATUS_JSON" | sed '$d')
  if [[ -n "$BODY" ]]; then
    HAS_POLL=$(node -e 'const fs=require("fs"); const input=fs.readFileSync(0,"utf8"); try{const d=JSON.parse(input); console.log(String(d.hasActivePoll ?? d.has_active_poll ?? "unknown"));}catch(e){console.log("unknown");}' <<<"$BODY")
  fi
else
  STATUS_CODE="no-key"
fi

echo "$NOW — Colosseum heartbeat/status checked (heartbeat=$HB_CODE, status=$STATUS_CODE, hasActivePoll=$HAS_POLL)." >> "$PROGRESS"
