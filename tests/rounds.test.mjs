import test from 'node:test';
import assert from 'node:assert/strict';
import { computeRoundStatus, getRoundWindow } from '../lib/rounds.js';

function d(iso){ return new Date(iso); }

test('Monday is registration', () => {
  assert.equal(computeRoundStatus(d('2026-02-09T10:00:00Z')), 'registration');
});

test('Wednesday is active', () => {
  assert.equal(computeRoundStatus(d('2026-02-11T12:00:00Z')), 'active');
});

test('Friday after close is closed', () => {
  assert.equal(computeRoundStatus(d('2026-02-13T19:00:00Z')), 'closed');
});

test('Saturday is break', () => {
  assert.equal(computeRoundStatus(d('2026-02-14T12:00:00Z')), 'break');
});

test('Round window is Tue-Fri', () => {
  const { activeStart, activeEnd } = getRoundWindow(d('2026-02-10T12:00:00Z'), 18);
  assert.equal(activeStart.toISOString(), '2026-02-10T00:00:00.000Z');
  assert.equal(activeEnd.toISOString(), '2026-02-13T18:00:00.000Z');
});
