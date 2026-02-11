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
PICK="${PICK:-5}"
TAGS="${TAGS:-}"

if [[ -z "$API_KEY" ]]; then
  echo "COLOSSEUM_API_KEY not set; aborting." >&2
  exit 1
fi

query="sort=$SORT&limit=$LIMIT&offset=$OFFSET"
if [[ -n "$TAGS" ]]; then
  IFS="," read -r -a taglist <<< "$TAGS"
  for tag in "${taglist[@]}"; do
    tag_trim=$(echo "$tag" | xargs)
    [[ -n "$tag_trim" ]] && query+="&tags=$tag_trim"
  done
fi

me_json=$(curl -s -H "Authorization: Bearer $API_KEY" "https://agents.colosseum.com/api/forum/me/comments?sort=new&limit=100&offset=0")
posts_json=$(curl -s "https://agents.colosseum.com/api/forum/posts?${query}")

ME_B64=$(printf '%s' "$me_json" | base64 -w 0)
POSTS_B64=$(printf '%s' "$posts_json" | base64 -w 0)

ME_B64="$ME_B64" POSTS_B64="$POSTS_B64" PICK="$PICK" node -e '
const me = JSON.parse(Buffer.from(process.env.ME_B64 || "", "base64").toString("utf8") || "{}");
const posts = JSON.parse(Buffer.from(process.env.POSTS_B64 || "", "base64").toString("utf8") || "{}");
const comments = Array.isArray(me.comments) ? me.comments : (Array.isArray(me) ? me : []);
const commented = new Set(comments.map(c => c.postId).filter(Boolean));
const list = (posts.posts || posts || [])
  .filter(p => p && !commented.has(p.id))
  .slice(0, Number(process.env.PICK || 5))
  .map(p => ({ id: p.id, title: p.title, tags: p.tags }));
console.log(JSON.stringify({ pick: list, commentedCount: commented.size }, null, 2));
'
