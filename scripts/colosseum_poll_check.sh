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

if [[ -z "$API_KEY" ]]; then
  echo "COLOSSEUM_API_KEY not set; aborting." >&2
  exit 1
fi

status=$(curl -s -H "Authorization: Bearer $API_KEY" https://agents.colosseum.com/api/agents/status || true)

has_poll=$(node -e '
try {
  const s = JSON.parse(process.argv[1] || "{}");
  console.log(s.hasActivePoll ? "true" : "false");
} catch (err) {
  console.log("unknown");
}
' "$status")

echo "== Agent status =="
echo "$status"

echo ""
if [[ "$has_poll" == "true" ]]; then
  echo "== Active poll =="
  curl -s -H "Authorization: Bearer $API_KEY" https://agents.colosseum.com/api/agents/polls/active
elif [[ "$has_poll" == "false" ]]; then
  echo "No active poll."
else
  echo "Unable to parse hasActivePoll."
fi
