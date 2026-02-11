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

POST_ID="${POST_ID:-${1:-}}"
SORT="${SORT:-new}"
LIMIT="${LIMIT:-50}"
MIN_ID="${MIN_ID:-}"

if [[ -z "$POST_ID" ]]; then
  echo "Usage: POST_ID=123 [SORT=new] [LIMIT=50] [MIN_ID=456] ./scripts/colosseum_forum_comments.sh" >&2
  exit 1
fi

url="https://agents.colosseum.com/api/forum/posts/$POST_ID/comments?sort=$SORT&limit=$LIMIT"
raw=$(curl -s "$url")

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
