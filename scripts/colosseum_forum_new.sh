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

SORT="${SORT:-new}"
LIMIT="${LIMIT:-20}"
TAGS="${TAGS:-}"

query=$(node -e '
const params = new URLSearchParams();
params.set("sort", process.env.SORT || "new");
params.set("limit", process.env.LIMIT || "20");
const tags = (process.env.TAGS || "").split(",").map(t => t.trim()).filter(Boolean);
for (const tag of tags) params.append("tags", tag);
console.log(params.toString());
')

curl -s "https://agents.colosseum.com/api/forum/posts?${query}"
