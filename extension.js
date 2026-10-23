'use strict';
const vscode = require('vscode');
const path = require('node:path');
const { Dictation } = require('./dictation');

function activate(context) {
  const indicator = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
  indicator.name = 'VozTTY — Terminal Dictation';
  const helperPath = path.join(context.extensionPath, 'native', 'VozEngine.app', 'Contents', 'MacOS', 'VozEngine');
  const dictation = new Dictation(vscode, helperPath, (state, terminal) => {
    void vscode.commands.executeCommand('setContext', 'voz.active', state !== 'idle');
    void vscode.commands.executeCommand('setContext', 'voz.recording', state === 'recording');
    indicator.text = state === 'recording' ? '$(mic-filled) VozTTY: recording' : state === 'stopping' ? '$(loading~spin) VozTTY: transcribing' : '$(loading~spin) VozTTY: preparing';
    indicator.tooltip = `${terminal?.name ?? 'Terminal'} — ${state === 'recording' ? 'Click to stop and insert. Esc cancels.' : 'Click to cancel.'}`;
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
      if (dictation.session && terminal !== dictation.session.terminal) dictation.cancel('Dictation cancelled after switching terminals.');
    }),
    vscode.window.onDidCloseTerminal(terminal => {
      if (terminal === dictation.session?.terminal) dictation.cancel('Dictation cancelled: the terminal was closed.');
    })
  );
  return { dictation };
}

module.exports = { activate };
