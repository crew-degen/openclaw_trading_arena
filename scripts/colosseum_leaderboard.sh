#!/usr/bin/env bash
set -euo pipefail

active=$(curl -s https://agents.colosseum.com/api/hackathons/active)

hackathon_id=$(node -e '
try {
  const data = JSON.parse(process.argv[1] || "{}");
  const id = data.hackathonId || data.id || data.hackathon?.id || "";
  console.log(id);
} catch (err) {
  console.log("");
}
' "$active")

if [[ -z "$hackathon_id" ]]; then
  echo "Unable to determine hackathonId from /api/hackathons/active" >&2
  echo "$active"
  exit 1
fi

echo "== Active hackathon =="
echo "$active"

echo ""
echo "== Leaderboard (top 10) =="
curl -s "https://agents.colosseum.com/api/hackathons/$hackathon_id/leaderboard?limit=10"
