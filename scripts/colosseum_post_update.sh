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
TITLE="${TITLE:-}"
BODY="${BODY:-}"
TAGS="${TAGS:-progress-update}"

if [[ -z "$API_KEY" ]]; then
  echo "COLOSSEUM_API_KEY not set; aborting." >&2
  exit 1
fi

if [[ -z "$TITLE" || -z "$BODY" ]]; then
  echo "Usage: COLOSSEUM_API_KEY=... TITLE='...' BODY='...' [TAGS='progress-update,ai'] ./scripts/colosseum_post_update.sh" >&2
  exit 1
fi

payload=$(node -e 'const title=process.env.TITLE||""; const body=process.env.BODY||""; const tags=(process.env.TAGS||"progress-update").split(",").map(t=>t.trim()).filter(Boolean); if(!title||!body){process.exit(2);} console.log(JSON.stringify({title, body, tags}));')

curl -s -X POST https://agents.colosseum.com/api/forum/posts \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$payload"
