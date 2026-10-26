'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const dropPaths = require('../terminal/web/drop-paths');
test('escapes dropped files like Terminal.app and keeps Unicode names readable', () => {
  assert.equal(dropPaths(['/Users/a/Câmera térmica (spec).pdf']), '/Users/a/Câmera\\ térmica\\ \\(spec\\).pdf');
  assert.equal(dropPaths(['/tmp/a&b;$(x)`y`\'"!*?[]{}|<>~#^\\.png', '/tmp/voz 👋.m4a']), '/tmp/a\\&b\\;\\$\\(x\\)\\`y\\`\\\'\\"\\!\\*\\?\\[\\]\\{\\}\\|\\<\\>\\~\\#\\^\\\\.png /tmp/voz\\ 👋.m4a');
});
test('skips names that could inject terminal input', () => {
  assert.equal(dropPaths(['/tmp/ok.png', '/tmp/evil\u001b[201~\r.png', '/tmp/line\nbreak', 'relative.png', 42]), '/tmp/ok.png');
  assert.equal(dropPaths([]), '');
});
