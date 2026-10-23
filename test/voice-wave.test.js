'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const voiceWave = require('../terminal/web/voice-wave');

test('keeps earlier voice peaks at their real positions in a twenty-second window', () => {
  const {path} = voiceWave([{at: 1000, level: 0.5}, {at: 11000, level: 1}, {at: 21000, level: 0}], [], 21000);
  assert.ok(path.includes('0,18.5'));
  assert.ok(path.includes('500,5'));
  assert.ok(path.includes('500,59'));
  assert.ok(path.includes('1000,32'));
  assert.ok(!voiceWave([{at: 1000, level: 1}], [], 22000).path.includes(',5'));
});

test('marks completed and ongoing pauses by elapsed wall time, then expires them', () => {
  const pauses = [{start: 5000, end: 9000}, {start: 10000}];
  assert.deepEqual(voiceWave([], pauses, 12000).bands, [{x: 650, width: 200}, {x: 900, width: 100}]);
  assert.deepEqual(voiceWave([], [{start: 5000, end: 9000}], 30000).bands, []);
});

test('does not invent activity when meter data stops and rejects invalid geometry', () => {
  const {path, bands} = voiceWave([{at: 1000, level: 1}, {at: NaN, level: 1}, {at: 2000, level: Infinity}], [{start: NaN}, {start: 1, end: NaN}], 2000);
  assert.ok(path.includes('970,32'));
  assert.ok(!path.includes('NaN'));
  assert.ok(!path.includes('Infinity'));
  assert.deepEqual(bands, []);
});
