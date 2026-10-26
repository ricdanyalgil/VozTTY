'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const promptRows = require('../terminal/web/prompt-rows');
const buffer = lines => ({getLine: i => lines[i] && ({isWrapped: !!lines[i][1], translateToString: () => lines[i][0]})});
test('accents CLI prompts and their wraps, not assistant text or shell output', () => {
  const lines = [['› Codex question'], ['wrapped question', true], ['• Answer'], ['❯ Claude question'], ['Response'], ['> Antigravity question'], ['answer'], ['user@Mac % ls'], ['>> code'], ['>comparison']];
  assert.deepEqual(promptRows(buffer(lines), 0, lines.length), [0, 1, 3, 5]);
  assert.deepEqual(promptRows(buffer(lines), 1, 4), [1, 3]);
  assert.deepEqual(promptRows(buffer([['> 场景 português 👋'], ['continuation', true]]), 0, 2), [0, 1]);
});
test('repainting removes a prompt accent when the CLI reuses a row', () => {
  const lines = [['› draft']];
  assert.deepEqual(promptRows(buffer(lines), 0, 1), [0]);
  lines[0][0] = 'Answer after redraw';
  assert.deepEqual(promptRows(buffer(lines), 0, 1), []);
  assert.deepEqual(promptRows(buffer([]), 0, 4), []);
});
test('keeps the whole prompt when the CLI breaks it into indented rows, as Claude Code does', () => {
  const lines = [
    ['❯ Uma coisa que eu quero consertar'], ['  com background cinza e o texto branco'], [''], ['  segundo parágrafo da mesma mensagem'],
    [''], ['· Enchanting… (4s)'], ['⏺ Resposta do assistente'], ['  continua a resposta indentada'],
    ['❯ Outra pergunta'], ['  ⎿  Interrupted'], ['────────'], ['❯ rascunho'], ['  segunda linha do rascunho'], ['────────'], ['  ? for shortcuts'],
  ];
  assert.deepEqual(promptRows(buffer(lines), 0, lines.length), [0, 1, 2, 3, 8, 11, 12]);
  // Starting mid-prompt still finds the opening row above the viewport.
  assert.deepEqual(promptRows(buffer(lines), 3, 5), [3]);
  assert.deepEqual(promptRows(buffer(lines), 7, 8), []);
});
