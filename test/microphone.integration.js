'use strict';
const vscode = require('vscode');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { spawn } = require('node:child_process');
const result = { mode: 'physical-microphone-acoustic-test', passed: false, states: [], nativeEvents: [], receivedBatches: 0, characters: 0, automaticEnter: false };
const save = () => fs.writeFileSync(process.env.VOZ_TEST_RESULT, JSON.stringify(result, null, 2));
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(check, message, timeout = 30000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    if (check()) return;
    if (result.error) throw new Error(result.error);
    await pause(100);
  }
  throw new Error(message);
}
module.exports.run = async () => {
  assert.equal(process.env.VOZ_TEST_MICROPHONE, '1', 'Este teste abre o microfone e reproduz uma frase. Defina VOZ_TEST_MICROPHONE=1 para o executar.');
  assert.ok(process.env.VOZ_TEST_RESULT, 'Defina VOZ_TEST_RESULT para os metadados de validação.');
  const received = [];
  const write = new vscode.EventEmitter();
  const terminal = vscode.window.createTerminal({ name: 'VozTTY — Teste do microfone físico', pty: {
    onDidWrite: write.event,
    open() { write.fire('VozTTY: teste acústico do microfone físico.\r\nEste terminal não executa comandos.\r\n> '); },
    close() {},
    handleInput(data) { received.push(data); write.fire(data); result.receivedBatches = received.length; result.characters = received.join('').length; result.automaticEnter = /[\r\n\x1b]/.test(received.join('')); save(); }
  } });
  let dictation;
  save();
  try {
    terminal.show();
    await until(() => vscode.window.activeTerminal === terminal, 'Terminal não ficou ativo.');
    ({ dictation } = await vscode.extensions.getExtension('danyalgil.voz-terminal').activate());
    const changed = dictation.changed;
    dictation.changed = (state, target) => { result.states.push({ state, at: new Date().toISOString() }); save(); changed(state, target); };
    const read = dictation.read.bind(dictation);
    dictation.read = (session, data) => { for (const line of data.split('\n').filter(Boolean)) { try { const event = JSON.parse(line); result.nativeEvents.push(event.type); } catch {} } save(); read(session, data); };
    const fail = dictation.fail.bind(dictation);
    dictation.fail = (session, message) => { if (dictation.session === session) { result.error = message; save(); } fail(session, message); };
    const children = [];
    const spawnHelper = dictation.spawnHelper;
    dictation.spawnHelper = (...args) => { const child = spawnHelper(...args); children.push(child); return child; };
    await vscode.commands.executeCommand('workbench.action.closeSidebar');
    await vscode.commands.executeCommand('voz.toggle');
    await until(() => dictation.session?.state === 'recording', 'O microfone ficou na preparação durante 30 segundos.');
    assert.equal(received.length, 0, 'Texto inserido antes de parar.');
    await vscode.commands.executeCommand('voz.cancel');
    await until(() => children[0].exitCode !== null || children[0].signalCode !== null, 'Cancelar não encerrou o motor.');
    assert.equal(received.length, 0, 'Cancelar inseriu texto.');
    result.cancellationPassed = true;
    await vscode.commands.executeCommand('voz.toggle');
    await until(() => dictation.session?.state === 'recording', 'Não foi possível recomeçar após cancelar.');
    await new Promise((resolve, reject) => {
      const voice = spawn('/usr/bin/say', ['-v', 'Luciana (Português (Brasil))', 'Quero falar com o terminal e transformar minha voz em texto.'], { stdio: 'ignore' });
      voice.on('error', reject);
      voice.on('close', code => code === 0 ? resolve() : reject(new Error('Falhou a reprodução da frase de teste.')));
    });
    await pause(800);
    await vscode.commands.executeCommand('voz.stop');
    await until(() => received.length > 0, 'A transcrição não chegou ao prompt.', 65000);
    assert.equal(received.length, 1, 'Texto duplicado.');
    assert.equal(result.automaticEnter, false, 'Recebeu Enter ou Escape.');
    assert.match(received[0], /terminal/i);
    assert.match(received[0], /texto/i);
    assert.equal(dictation.session, undefined);
    await until(() => children[1].exitCode !== null || children[1].signalCode !== null, 'O motor não encerrou após a transcrição.');
    await pause(500);
    assert.equal(result.error, undefined);
    result.helperExited = true;
    result.expectedWords = true;
    result.passed = true;
    save();
    write.fire('\r\n\r\nTeste aprovado: captação física e inserção sem Enter.\r\n');
  } catch (error) {
    result.error = error.message;
    save();
    throw error;
  } finally {
    dictation?.cancel();
    terminal.dispose();
    write.dispose();
  }
};
