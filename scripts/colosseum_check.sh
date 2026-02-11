#!/usr/bin/env bash
set -euo pipefail

API_KEY="${COLOSSEUM_API_KEY:-${AGENTS_API_KEY:-}}"

echo "== Colosseum skill.md (head) =="
curl -s https://colosseum.com/skill.md | head -10 || true

echo ""
echo "== Colosseum heartbeat (head) =="
curl -s https://colosseum.com/heartbeat.md | head -20 || true

echo ""
echo "== Colosseum API health =="
curl -s -o /dev/null -w "%{http_code}\n" https://agents.colosseum.com/api/hackathons

if [[ -z "$API_KEY" ]]; then
  echo ""
  echo "COLOSSEUM_API_KEY not set; skipping agent status check."
  exit 0
fi

echo ""
echo "== Agent status =="
curl -s -H "Authorization: Bearer $API_KEY" https://agents.colosseum.com/api/agents/status
