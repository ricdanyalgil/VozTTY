'use strict';
const vscode = require('vscode');
const path = require('node:path');
const fs = require('node:fs/promises');
const os = require('node:os');
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
    vscode.commands.registerCommand('voz.editVocabulary', async () => {
      const file = path.join(os.homedir(), 'Library', 'Application Support', 'VozTTY', 'vocabulary.txt');
      try {
        await fs.mkdir(path.dirname(file), { recursive: true, mode: 0o700 });
        try {
          await fs.copyFile(path.join(context.extensionPath, 'vocabulary.txt'), file, require('node:fs').constants.COPYFILE_EXCL);
          await fs.chmod(file, 0o600);
        } catch (error) { if (error.code !== 'EEXIST') throw error; }
        await vscode.window.showTextDocument(await vscode.workspace.openTextDocument(vscode.Uri.file(file)));
      } catch (error) { void vscode.window.showErrorMessage(`Could not open vocabulary: ${error.message}`); }
    }),
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
