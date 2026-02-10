import test from 'node:test';
import assert from 'node:assert/strict';

globalThis.__APP_TEST__ = true;

const { fmt, fmtPct, drawChart, normalizeHistory } = await import('../public/app.js');

test('fmt formats numbers and handles null', () => {
  assert.equal(fmt(null), '—');
  assert.equal(fmt(undefined), '—');
  assert.equal(fmt(1.234), '1.23');
});

test('fmtPct formats percentages with sign', () => {
  assert.equal(fmtPct(null), '—');
  assert.equal(fmtPct(0), '0.00%');
  assert.equal(fmtPct(1.2), '+1.20%');
  assert.equal(fmtPct(-1.2), '-1.20%');
});

test('normalizeHistory maps various shapes', () => {
  const raw = { ticks: [
    { created_at: '2026-02-10T00:00:00Z', price: '123' },
    { ts: 1700000000, p: 100 }
  ]};
  const data = normalizeHistory(raw);
  assert.equal(data.length, 2);
  assert.equal(typeof data[0].price, 'number');
  assert.ok(data[0].t instanceof Date);
  assert.ok(data[0].t <= data[1].t);
});

test('drawChart renders without throwing', () => {
  const calls = [];
  const ctx = {
    clearRect: () => calls.push('clearRect'),
    beginPath: () => calls.push('beginPath'),
    moveTo: (x,y) => calls.push(['moveTo', x, y]),
    lineTo: (x,y) => calls.push(['lineTo', x, y]),
    stroke: () => calls.push('stroke'),
    set strokeStyle(v){ this._strokeStyle = v; },
    get strokeStyle(){ return this._strokeStyle; },
    lineWidth: 1,
  };
  const canvas = { width: 100, height: 50, getContext: () => ctx };
  globalThis.document = {
    getElementById: (id) => (id === 'pnlChart' ? canvas : null)
  };

  drawChart([[{ x: 0, y: 1 }, { x: 1, y: 2 }]]);
  assert.ok(calls.includes('stroke'));
});
