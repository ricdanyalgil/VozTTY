'use strict';
const vscode = require('vscode');
const path = require('node:path');
const { Dictation } = require('./dictation');

function activate(context) {
  const indicator = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  indicator.name = 'Voz — Ditado no terminal';
  const helperPath = path.join(context.extensionPath, 'native', 'VozEngine.app', 'Contents', 'MacOS', 'VozEngine');
  const dictation = new Dictation(vscode, helperPath, (state, terminal) => {
    void vscode.commands.executeCommand('setContext', 'voz.active', state !== 'idle');
    void vscode.commands.executeCommand('setContext', 'voz.recording', state === 'recording');
    indicator.text = state === 'recording' ? '$(mic-filled) Voz: a gravar' : state === 'stopping' ? '$(loading~spin) Voz: a transcrever' : '$(loading~spin) Voz: a preparar';
    indicator.tooltip = `${terminal?.name ?? 'Terminal'} — ${state === 'recording' ? 'Clique para parar e inserir. Esc cancela.' : 'Clique para cancelar.'}`;
    indicator.command = state === 'recording' ? 'voz.stop' : 'voz.cancel';
    indicator.accessibilityInformation = { label: indicator.text.replace(/\$\([^)]*\)/g, '') };
    if (state === 'idle') indicator.hide(); else indicator.show();
  });
  context.subscriptions.push(
    indicator, dictation,
    vscode.commands.registerCommand('voz.toggle', () => dictation.start()),
    vscode.commands.registerCommand('voz.stop', () => dictation.stop()),
    vscode.commands.registerCommand('voz.cancel', () => dictation.cancel()),
    vscode.window.onDidChangeActiveTerminal(terminal => {
      if (dictation.session && terminal !== dictation.session.terminal) dictation.cancel('Ditado cancelado ao mudar de terminal.');
    }),
    vscode.window.onDidCloseTerminal(terminal => {
      if (terminal === dictation.session?.terminal) dictation.cancel('Ditado cancelado: o terminal foi fechado.');
    })
  );
  return { dictation };
}

module.exports = { activate };
