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
BODY="${BODY:-}"

if [[ -z "$API_KEY" ]]; then
  echo "COLOSSEUM_API_KEY not set; aborting." >&2
  exit 1
fi

if [[ -z "$POST_ID" || -z "$BODY" ]]; then
  echo "Usage: POST_ID=123 BODY='Your comment' ./scripts/colosseum_forum_comment.sh" >&2
  exit 1
fi

payload=$(node -e 'const body=process.env.BODY||""; if(!body){process.exit(2);} console.log(JSON.stringify({body}));')

curl -s -X POST "https://agents.colosseum.com/api/forum/posts/$POST_ID/comments" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload"
