#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_posts.log}"
LIMIT="${LIMIT:-20}"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Log file not found: $LOG_FILE" >&2
  exit 1
fi

node - <<'NODE'
const fs = require('fs');
const file = process.env.LOG_FILE;
const limit = parseInt(process.env.LIMIT || '20', 10);
const raw = fs.readFileSync(file, 'utf8').trim();
if (!raw) process.exit(0);
const lines = raw.split(/\n+/);
const map = new Map();
for (const line of lines) {
  const cols = line.split('\t');
  if (cols.length < 4) continue;
  const ts = cols[0] || '';
  const status = cols[1] || '';
  const id = cols[2] || '';
  const title = cols[3] || '';
  const err = cols[4] || '';
  const verify = cols[5] || '';
  if (!id) continue;
  const needsVerify = !!verify || /verification/i.test(err) || /verify/i.test(err);
  if (!needsVerify) continue;
  map.set(id, { ts, status, id, title, err, verify });
}
const rows = Array.from(map.values()).slice(-limit);
for (const r of rows) {
  const parts = [r.ts, r.id, r.title || ''];
  if (r.err) parts.push(`err=${r.err}`);
  if (r.verify) parts.push(`verify=${r.verify}`);
  console.log(parts.join('\t'));
}
NODE
