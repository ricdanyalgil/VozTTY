'use strict';
const vscode = require('vscode');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { terminalText } = require('../dictation');
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(check, message, timeout = 45000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) { if (check()) return; await pause(100); }
  throw Error(message);
}
exports.run = async () => {
  assert.ok(process.env.VOZ_TEST_AUDIO && process.env.VOZ_TEST_RESULT && process.env.VOZ_TEST_HEADLESS, 'Set VOZ_TEST_AUDIO, VOZ_TEST_RESULT and VOZ_TEST_HEADLESS.');
  const pty = require(path.join(vscode.env.appRoot, 'node_modules.asar', 'node-pty'));
  const { Terminal } = require(process.env.VOZ_TEST_HEADLESS);
  const { dictation } = await vscode.extensions.getExtension('danyalgil.voz-terminal').activate();
  const report = { host: 'VS Code integrated terminal / test PTY', source: 'long synthetic speech file / real Apple ASR', automaticEnter: false, cases: [] };
  const save = () => fs.writeFileSync(process.env.VOZ_TEST_RESULT, JSON.stringify(report, null, 2));
  const cases = [
    {name: 'Codex CLI', file: process.env.VOZ_TEST_CODEX, args: ['--no-daemon', '--no-alt-screen', '--sandbox', 'read-only', '--ask-for-approval', 'on-request'], ready: /Ask Codex to do anything|To get started, describe a task/},
    {name: 'Claude Code', file: process.env.VOZ_TEST_CLAUDE, args: ['--safe-mode', '--strict-mcp-config', '--tools', ''], ready: /for shortcuts|Try "|Claude Code v/}
  ];
  for (const target of cases) {
    const item = { name: target.name, passed: false }; report.cases.push(item); save();
    let child, terminal;
    const output = new vscode.EventEmitter();
    const screen = new Terminal({cols: 120, rows: 36, scrollback: 5000, allowProposedApi: true});
    const snapshot = () => {
      const buffer = screen.buffer.active;
      let text = '';
      for (let i = 0; i < buffer.length; i++) { const line = buffer.getLine(i); if (i && !line?.isWrapped) text += '\n'; text += line?.translateToString(!buffer.getLine(i + 1)?.isWrapped) ?? ''; }
      return text;
    };
    const cwd = fs.mkdtempSync(path.join(os.tmpdir(), 'voztty-workspace.'));
    let observedText, deliveryInput = "";
    dictation.spawnHelper = (helper, args, options) => {
      const engine = spawn(helper, [...args, "--file", process.env.VOZ_TEST_AUDIO], options);
      let buffer = ""; engine.stdout.setEncoding("utf8");
      engine.stdout.on("data", chunk => { buffer += chunk; let end; while ((end = buffer.indexOf("\n")) >= 0) { const event = JSON.parse(buffer.slice(0, end)); buffer = buffer.slice(end + 1); if (event.type === "final") observedText = terminalText(event.text); } });
      return engine;
    };
    const stopChild = () => { try { child?.kill(); } catch {} child = undefined; };
    try {
      assert.ok(target.file, `Missing executable for ${target.name}`);
      terminal = vscode.window.createTerminal({name: `VozTTY — ${target.name} test`, pty: {
        onDidWrite: output.event,
        open(dimensions) {
          const cols = dimensions?.columns ?? 120, rows = dimensions?.rows ?? 36;
          screen.resize(cols, rows);
          child = pty.spawn(target.file, target.args, {name: 'xterm-256color', cols, rows, cwd, env: {...process.env, TERM: 'xterm-256color', TERM_PROGRAM: 'vscode'}});
          child.onData(data => { output.fire(data); screen.write(data); });
        },
        close() { stopChild(); },
        handleInput(data) { if (observedText) deliveryInput += data; child?.write(data); },
        setDimensions({columns, rows}) { child?.resize(columns, rows); screen.resize(columns, rows); }
      }});
      terminal.show();
      await until(() => child && vscode.window.activeTerminal === terminal, 'Terminal did not become active.');
      if (target.name === 'Claude Code') {
        await until(() => /Accessing workspace:/.test(snapshot()) || target.ready.test(snapshot()), 'Claude did not reach setup or composer.');
        if (/Yes, I trust this folder/.test(snapshot())) {
          assert.equal(fs.readdirSync(cwd).length, 0, 'Only trust this empty test directory.');
          await pause(1500); child.write('\x1b[B'); await pause(300); child.write('\r');
          item.disposableWorkspaceSetup = true;
        }
      }
      await until(() => target.ready.test(snapshot()), 'CLI did not reach its input composer.');
      terminal.sendText('VozTTY test: ', false);
      await pause(400);
      await vscode.commands.executeCommand('voz.toggle');
      await until(() => dictation.session?.state === 'recording', 'Recognition engine did not become ready.');
      await vscode.commands.executeCommand('voz.stop');
      await until(() => observedText && deliveryInput.includes(observedText), 'No transcript delivered to the PTY.', 65000);
      assert.ok(!/[\r\n]/.test(deliveryInput), 'Return reached the CLI.');
      assert.ok(!/[\r\n\x1b]/.test(observedText));
      assert.match(observedText, /^Quero organizar/i);
      assert.match(observedText, /janela de teste[.!]?$/i);
      await pause(3000);
      const visible = snapshot().replace(/\s+/g, ' ');
      assert.match(visible, /VozTTY test:/);
      const tail = observedText.split(/\s+/).slice(-5).join(' ');
      assert.ok(visible.includes(tail) || /pasted (?:text|content)|paste again/i.test(visible), 'Draft not visible in the CLI.');
      Object.assign(item, {passed: true, characters: observedText.length, words: observedText.split(/\s+/).length, automaticEnter: false, draftVisible: true});
    } catch (error) { item.error = error.message; fs.writeFileSync(process.env.VOZ_TEST_RESULT + '.' + target.name.replace(/ /g, '-') + '.txt', snapshot()); }
    finally { dictation.cancel(); terminal?.dispose(); stopChild(); screen.dispose(); output.dispose(); save(); }
  }
  report.passed = report.cases.every(item => item.passed);
  save();
};
