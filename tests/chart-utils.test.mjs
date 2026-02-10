import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeHistory } from '../public/chart-utils.js';

test('normalizeHistory handles ticks + created_at', () => {
  const raw = { ticks: [{ price: 123, created_at: '2026-02-10T00:00:00Z' }] };
  const out = normalizeHistory(raw);
  assert.equal(out.length, 1);
  assert.equal(out[0].price, 123);
  assert.ok(out[0].t instanceof Date);
});

test('normalizeHistory handles numeric seconds timestamp', () => {
  const raw = [{ price: 5, timestamp: 1700000000 }];
  const out = normalizeHistory(raw);
  assert.equal(out.length, 1);
  assert.equal(out[0].price, 5);
  assert.ok(out[0].t.getTime() > 1700000000);
});
