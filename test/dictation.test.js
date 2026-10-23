'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const { PassThrough } = require('node:stream');
const { Dictation, terminalText } = require('../dictation');

function setup() {
  const writes = [], errors = [], infos = [], states = [];
  const terminal = { name: 'Claude', sendText: (...args) => writes.push(args), show() {} };
  const child = new EventEmitter();
  Object.assign(child, { stdout: new PassThrough(), stderr: new PassThrough(), stdin: new PassThrough(), exitCode: null, killed: false });
  child.kill = () => { child.killed = true; child.emit('close', 0); };
  const vscode = {
    window: {
      activeTerminal: terminal, terminals: [terminal], setStatusBarMessage() {},
      showErrorMessage: text => errors.push(text), showInformationMessage: text => infos.push(text)
    },
    workspace: { getConfiguration: () => ({ get: () => 'pt-BR' }) }
  };
  const dictation = new Dictation(vscode, '/test/helper', state => states.push(state), () => child);
  const event = value => child.stdout.write(JSON.stringify(value) + '\n');
  return { dictation, vscode, terminal, child, event, writes, errors, infos, states };
}

test('preserves narrative punctuation, accents and emoji; removes terminal controls and line breaks', () => {
  assert.equal(terminalText('  Olá!\r\nReveja a API, por favor.\t🚀\u001b\u0000\u0085 '), 'Olá! Reveja a API, por favor. 🚀');
  assert.equal(terminalText('$(teste) `código`'), '$(teste) `código`');
});

test('inserts exactly once into the origin, explicitly without Enter, only after Stop', () => {
  const s = setup();
  s.dictation.start();
  s.event({ type: 'ready' });
  assert.deepEqual(s.writes, []);
  s.dictation.stop();
  s.event({ type: 'final', text: 'Olá.\nQuero rever isto!' });
  s.event({ type: 'final', text: 'duplicado' });
  assert.deepEqual(s.writes, [['Olá. Quero rever isto!', false]]);
  assert.deepEqual(s.states, ['preparing', 'recording', 'stopping', 'idle']);
  s.child.kill();
});

test('never redirects a result when another terminal becomes active', () => {
  const s = setup();
  s.dictation.start(); s.event({ type: 'ready' }); s.dictation.stop();
  s.vscode.window.activeTerminal = { sendText() { assert.fail('wrong terminal'); } };
  s.event({ type: 'final', text: 'não entregar' });
  assert.deepEqual(s.writes, []);
  assert.equal(s.dictation.session, undefined);
  s.child.kill();
});

test('does not deliver to a closed terminal or accept a late result after cancel', () => {
  for (const action of ['close', 'cancel']) {
    const s = setup();
    s.dictation.start(); s.event({ type: 'ready' }); s.dictation.stop();
    if (action === 'close') s.vscode.window.terminals = [];
    else s.dictation.cancel();
    s.event({ type: 'final', text: 'não entregar' });
    assert.deepEqual(s.writes, []);
    s.child.kill();
  }
});

test('buffers fragmented JSON and Unicode without inserting partial input', () => {
  const s = setup();
  s.dictation.start(); s.event({ type: 'ready' }); s.dictation.stop();
  const data = Buffer.from(JSON.stringify({ type: 'final', text: 'ação 🚀' }) + '\n');
  for (const byte of data) s.child.stdout.write(Buffer.from([byte]));
  assert.deepEqual(s.writes, [['ação 🚀', false]]);
  s.child.kill();
});

test('rejects malformed, oversized and out-of-order responses without typing anything', () => {
  for (const data of ['oops\n', '{"type":"final","text":"prematuro"}\n', 'x'.repeat(1024 * 1024 + 1), 'null\n']) {
    const s = setup(); s.dictation.start();
    s.child.stdout.write(data);
    assert.deepEqual(s.writes, []);
    assert.equal(s.errors.length, 1);
    s.child.kill();
  }
});

test('surfaces permission failures without inserting a transcript', () => {
  const s = setup();
  s.dictation.start(); s.event({ type: 'error', message: 'Microfone recusado' });
  assert.deepEqual(s.errors, ['Microfone recusado']);
  assert.deepEqual(s.writes, []);
  assert.equal(s.dictation.session, undefined);
  s.child.kill();
});

test('a process crash resets the session without inserting text', () => {
  const s = setup();
  s.dictation.start(); s.event({ type: 'ready' });
  s.child.exitCode = 1;
  s.child.emit('close', 1);
  assert.equal(s.dictation.session, undefined);
  assert.equal(s.errors.length, 1);
  assert.deepEqual(s.writes, []);
});

test('finishing never writes to a helper pipe that may already be closed', () => {
  for (const action of ['final', 'cancel', 'error']) {
    const s = setup();
    const signals = [];
    const kill = s.child.kill;
    s.child.kill = signal => { signals.push(signal); kill(); };
    s.dictation.start(); s.event({ type: 'ready' });
    if (action === 'final') {
      s.dictation.stop();
      s.event({ type: 'final', text: 'Texto para rever.' });
      assert.equal(s.child.stdin.read().toString(), 'stop\n');
    } else {
      if (action === 'cancel') s.dictation.cancel();
      else s.event({ type: 'error', message: 'Microfone indisponível' });
      assert.equal(s.child.stdin.read(), null);
    }
    assert.deepEqual(signals, ['SIGTERM']);
    assert.equal(s.dictation.session, undefined);
  }
});

test('does not start a helper without a selected terminal', () => {
  const s = setup();
  s.vscode.window.activeTerminal = undefined;
  s.dictation.start();
  assert.equal(s.dictation.session, undefined);
  assert.equal(s.infos.length, 1);
});
