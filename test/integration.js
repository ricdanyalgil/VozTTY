'use strict';
const vscode = require('vscode');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const { spawn } = require('node:child_process');

async function until(check, message) {
  const deadline = Date.now() + 45000;
  while (Date.now() < deadline) {
    if (check()) return;
    await new Promise(resolve => setTimeout(resolve, 50));
  }
  throw new Error(message);
}

async function run() {
  const received = [];
  const write = new vscode.EventEmitter();
  const terminal = vscode.window.createTerminal({ name: 'Voz — teste de inserção', pty: {
    onDidWrite: write.event,
    open() { write.fire('Teste do Voz: sem comandos de shell.\r\n> '); },
    close() {}, handleInput(data) { received.push(data); write.fire(data); }
  } });
  try {
    terminal.show();
    await until(() => vscode.window.activeTerminal === terminal, 'O terminal de teste não ficou ativo.');
    const extension = vscode.extensions.getExtension('danyalgil.voz-terminal');
    assert.ok(extension, 'Extensão não descoberta');
    const { dictation } = await extension.activate();
    // Use a synthetic recording; exercise the real ASR and terminal API without opening the microphone.
    assert.ok(process.env.VOZ_TEST_AUDIO, 'Defina VOZ_TEST_AUDIO para um ficheiro de fala sintética.');
    dictation.spawnHelper = (helper, args, options) => spawn(helper, [...args, '--file', process.env.VOZ_TEST_AUDIO], options);
    await vscode.commands.executeCommand('voz.toggle');
    await until(() => dictation.session?.state === 'recording', 'O motor não iniciou: verifique a notificação de erro.');
    assert.equal(received.length, 0, 'Inseriu antes de terminar o ditado');
    await vscode.commands.executeCommand('voz.stop');
    await until(() => received.length > 0, 'A transcrição não chegou ao terminal');
    const text = received.join('');
    assert.match(text, /terminal/i);
    assert.match(text, /texto/i);
    assert.ok(!/[\r\n\u001b]/.test(text), `Recebeu caracteres de execução: ${JSON.stringify(text)}`);
    assert.equal(received.length, 1, 'Transcrição duplicada');
    assert.equal(dictation.session, undefined);
    const result = { passed: true, terminalAPI: true, nativeTranscription: true, automaticEnter: false, received: text };
    if (process.env.VOZ_TEST_RESULT) await fs.writeFile(process.env.VOZ_TEST_RESULT, JSON.stringify(result, null, 2));
    console.log('VOZ INTEGRATION OK', JSON.stringify(result));
  } finally {
    terminal.dispose();
    write.dispose();
  }
}

module.exports = { run };
