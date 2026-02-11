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
SORT="${SORT:-new}"
LIMIT="${LIMIT:-50}"
OFFSET="${OFFSET:-0}"
MIN_ID="${MIN_ID:-}"

if [[ -z "$API_KEY" ]]; then
  echo "COLOSSEUM_API_KEY not set; aborting." >&2
  exit 1
fi

url="https://agents.colosseum.com/api/forum/me/comments?sort=$SORT&limit=$LIMIT&offset=$OFFSET"
raw=$(curl -s -H "Authorization: Bearer $API_KEY" "$url")

if [[ -n "$MIN_ID" ]]; then
  node -e '
const minId = Number(process.env.MIN_ID || 0);
const data = JSON.parse(process.argv[1] || "{}");
const comments = Array.isArray(data.comments) ? data.comments : [];
const filtered = comments.filter(c => typeof c.id === "number" && c.id > minId);
console.log(JSON.stringify({ ...data, comments: filtered }, null, 2));
' "$raw"
else
  echo "$raw"
fi
