'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');

test('vocabulary command creates a private starter and preserves existing edits', async () => {
  const home = await fs.mkdtemp(path.join(os.tmpdir(), 'voztty-vocabulary-'));
  const commands = new Map();
  let opened;
  const vscode = {
    StatusBarAlignment: { Right: 1 },
    Uri: { file: value => value },
    commands: { registerCommand: (name, callback) => { commands.set(name, callback); return {}; } },
    workspace: { openTextDocument: async file => file },
    window: {
      createStatusBarItem: () => ({}),
      showTextDocument: async file => { opened = file; },
      showErrorMessage: message => { throw new Error(message); },
      onDidChangeActiveTerminal: () => ({}), onDidCloseTerminal: () => ({})
    }
  };
  try {
    const sandbox = { module: { exports: {} }, require: name => name === 'vscode' ? vscode : name === 'node:os' ? { homedir: () => home } : name === './dictation' ? require('../dictation') : require(name) };
    vm.runInNewContext(await fs.readFile(path.join(__dirname, '../extension.js'), 'utf8'), sandbox);
    sandbox.module.exports.activate({ extensionPath: path.join(__dirname, '..'), subscriptions: [] });
    const edit = commands.get('voz.editVocabulary');
    await edit();
    assert.equal(opened, path.join(home, 'Library/Application Support/VozTTY/vocabulary.txt'));
    assert.equal(await fs.readFile(opened, 'utf8'), await fs.readFile(path.join(__dirname, '../vocabulary.txt'), 'utf8'));
    assert.equal((await fs.stat(opened)).mode & 0o777, 0o600);
    await fs.writeFile(opened, 'MyProject = My Project\n');
    await edit();
    assert.equal(await fs.readFile(opened, 'utf8'), 'MyProject = My Project\n');
  } finally { await fs.rm(home, { recursive: true, force: true }); }
});
