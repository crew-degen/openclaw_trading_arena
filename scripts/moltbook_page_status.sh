#!/usr/bin/env bash
set -euo pipefail

INPUT="${POST_URL:-${POST_ID:-${1:-}}}"
if [[ -z "$INPUT" ]]; then
  echo "Usage: POST_URL=<url|id> ./scripts/moltbook_page_status.sh" >&2
  exit 1
fi

if echo "$INPUT" | grep -Eq '^https?://'; then
  URL="$INPUT"
else
  if echo "$INPUT" | grep -Eq '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
    URL="https://www.moltbook.com/post/$INPUT"
  else
    # try to extract UUID from string
    id=$(echo "$INPUT" | grep -Eo '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | head -n1 || true)
    if [[ -z "$id" ]]; then
      echo "Could not extract post id from: $INPUT" >&2
      exit 1
    fi
    URL="https://www.moltbook.com/post/$id"
  fi
fi

# Fetch page (follow redirects) and check for 404 title marker
html=$(curl -sL "$URL")
if echo "$html" | grep -q "404: This page could not be found"; then
  echo "NOT_FOUND\t$URL"
  exit 2
fi

if [[ -z "$html" ]]; then
  echo "EMPTY_RESPONSE\t$URL" >&2
  exit 3
fi

echo "FOUND\t$URL"
