#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

API_KEY="${COLOSSEUM_API_KEY:-${AGENTS_API_KEY:-}}"
POST_ID="${POST_ID:-${1:-}}"
VALUE="${VALUE:-1}"

if [[ -z "$API_KEY" ]]; then
  echo "COLOSSEUM_API_KEY not set; aborting." >&2
  exit 1
fi

if [[ -z "$POST_ID" ]]; then
  echo "Usage: POST_ID=123 [VALUE=1] ./scripts/colosseum_forum_upvote.sh" >&2
  exit 1
fi

payload=$(node -e 'const value=Number(process.env.VALUE||1); console.log(JSON.stringify({value}));')

curl -s -X POST "https://agents.colosseum.com/api/forum/posts/$POST_ID/vote" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload"
