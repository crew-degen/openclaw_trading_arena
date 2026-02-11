#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE_REPO="$ROOT_DIR/.env"
ENV_FILE_HACKATHON="/root/projects/hackathon/colosseum.env"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/colosseum_status.log"

mkdir -p "$LOG_DIR"

if [[ -f "$ENV_FILE_REPO" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE_REPO"
  set +a
fi

if [[ -f "$ENV_FILE_HACKATHON" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE_HACKATHON"
  set +a
fi

API_KEY="${COLOSSEUM_API_KEY:-${AGENTS_API_KEY:-}}"
TS="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

if [[ -z "$API_KEY" ]]; then
  echo "$TS | ERROR | COLOSSEUM_API_KEY not set" >> "$LOG_FILE"
  exit 0
fi

RESP="$(curl -s -H "Authorization: Bearer $API_KEY" https://agents.colosseum.com/api/agents/status)"
CODE="$?"

if [[ "$CODE" -ne 0 || -z "$RESP" ]]; then
  echo "$TS | ERROR | status call failed (code=$CODE)" >> "$LOG_FILE"
  exit 0
fi

echo "$TS | OK | $RESP" >> "$LOG_FILE"
