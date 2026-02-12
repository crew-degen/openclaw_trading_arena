#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/root/projects/openclaw_trading_arena/logs/moltbook_posts.log}"
LIMIT="${LIMIT:-20}"
MODE="${MODE:-all}" # all | errors | verify

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Log file not found (nothing to summarize): $LOG_FILE" >&2
  exit 0
fi

node - <<'NODE'
const fs = require('fs');
const file = process.env.LOG_FILE;
const limit = parseInt(process.env.LIMIT || '20', 10);
const mode = (process.env.MODE || 'all').toLowerCase();
const data = fs.readFileSync(file, 'utf8').trim();
if (!data) process.exit(0);
const lines = data.split(/\n+/).slice(-Math.max(limit * 5, 200));
const out = [];
for (const line of lines) {
  const cols = line.split('\t');
  if (cols.length < 5) continue;
  const ts = cols[0] || '';
  let type = 'post';
  let status = '';
  let id = '';
  let title = '';
  let postId = '';
  let err = '';
  let verify = '';
  if (['ok','error','non_json'].includes((cols[1]||'').toLowerCase())) {
    // posts log: ts, status, id, title, err, verify
    status = cols[1] || '';
    id = cols[2] || '';
    title = cols[3] || '';
    err = cols[4] || '';
    verify = cols[5] || '';
    type = 'post';
  } else {
    // comments log: ts, post_id, status, id, err, verify
    postId = cols[1] || '';
    status = cols[2] || '';
    id = cols[3] || '';
    err = cols[4] || '';
    verify = cols[5] || '';
    type = 'comment';
  }

  const hasError = status.toLowerCase() === 'error' || !!err;
  const needsVerify = !!verify;

  if (mode === 'errors' && !hasError) continue;
  if (mode === 'verify' && !needsVerify) continue;

  out.push({ ts, type, status, id, title, postId, err, verify });
}

const tail = out.slice(-limit);
for (const row of tail) {
  const parts = [row.ts, row.type, row.status, row.id];
  if (row.postId) parts.push(`post=${row.postId}`);
  if (row.title) parts.push(`title=${row.title}`);
  if (row.err) parts.push(`err=${row.err}`);
  if (row.verify) parts.push(`verify=${row.verify}`);
  console.log(parts.join('\t'));
}
NODE
