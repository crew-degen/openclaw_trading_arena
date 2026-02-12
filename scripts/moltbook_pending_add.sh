#!/usr/bin/env bash
set -euo pipefail

PENDING_FILE="${PENDING_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_pending_ids.txt}"
POST_ID="${POST_ID:-${1:-}}"
TITLE="${TITLE:-${2:-}}"

if [[ -z "$POST_ID" ]]; then
  echo "Usage: POST_ID=<uuid> [TITLE=\"title\"] ./scripts/moltbook_pending_add.sh" >&2
  exit 1
fi

if ! echo "$POST_ID" | grep -Eq '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
  echo "POST_ID must be a UUID" >&2
  exit 1
fi

mkdir -p "$(dirname "$PENDING_FILE")"

line="$POST_ID"
if [[ -n "$TITLE" ]]; then
  line="$POST_ID\t$TITLE"
fi

if [[ -f "$PENDING_FILE" ]]; then
  if grep -q "^$POST_ID\t" "$PENDING_FILE" || grep -q "^$POST_ID$" "$PENDING_FILE"; then
    echo "Already in pending list: $POST_ID" >&2
    exit 0
  fi
fi

echo -e "$line" >> "$PENDING_FILE"
