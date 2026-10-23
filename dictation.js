'use strict';
const { spawn } = require('node:child_process');

function terminalText(text) {
  // Never let ASR output contain Return, Escape, Tab or other terminal control keys.
  return text.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f-\u009f]/gu, '').replace(/\s+/gu, ' ').trim();
}

class Dictation {
  constructor(vscode, helperPath, changed = () => {}, spawnHelper = spawn) {
    this.vscode = vscode;
    this.helperPath = helperPath;
    this.changed = changed;
    this.spawnHelper = spawnHelper;
    this.session = undefined;
  }

  start() {
    if (this.session) return;
    const terminal = this.vscode.window.activeTerminal;
    if (!terminal) return void this.vscode.window.showInformationMessage('Open and select a terminal before starting dictation.');
    if (process.platform !== 'darwin' || process.arch !== 'arm64') {
      return void this.vscode.window.showErrorMessage('VozTTY requires an Apple Silicon Mac running macOS 26 or later.');
    }
    const language = this.vscode.workspace.getConfiguration('voz').get('language', 'pt-BR');
    if (!['pt-BR', 'pt-PT', 'en-US'].includes(language)) return void this.vscode.window.showErrorMessage('Invalid dictation language.');
    const session = { terminal, state: 'preparing', buffer: '', child: undefined, timer: undefined };
    this.session = session;
    this.changed(session.state, terminal);
    try {
      session.child = this.spawnHelper(this.helperPath, ['--language', language], { stdio: ['pipe', 'pipe', 'pipe'] });
      const child = session.child;
      child.stdout.setEncoding('utf8');
      child.stdout.on('data', data => this.read(session, data));
      // The native framework may log diagnostics to stderr; never log audio or transcripts.
      child.stderr.resume();
      child.on('error', error => this.fail(session, `Could not start the microphone: ${error.message}`));
      child.stdin.on('error', () => this.fail(session, 'The microphone connection was interrupted.'));
      child.on('close', () => {
        if (this.session === session) this.fail(session, 'Recognition ended without returning text. Try again.');
      });
    } catch (error) {
      this.fail(session, `Could not start dictation: ${error.message}`);
    }
  }

  stop() {
    const session = this.session;
    if (!session || session.state !== 'recording') return;
    session.state = 'stopping';
    this.changed(session.state, session.terminal);
    session.child.stdin.write('stop\n');
    session.timer = setTimeout(() => this.fail(session, 'Transcription timed out. Dictation was cancelled; nothing was sent.'), 60000);
    session.timer.unref();
  }

  read(session, data) {
    if (this.session !== session) return;
    session.buffer += data;
    if (Buffer.byteLength(session.buffer, 'utf8') > 1024 * 1024) return this.fail(session, 'Recognition response is too large.');
    let newline;
    while (this.session === session && (newline = session.buffer.indexOf('\n')) !== -1) {
      const line = session.buffer.slice(0, newline);
      session.buffer = session.buffer.slice(newline + 1);
      let event;
      try { event = JSON.parse(line); } catch { return this.fail(session, 'Invalid recognition response.'); }
      if (!event || typeof event !== 'object') return this.fail(session, 'Invalid recognition response.');
      if (event.type === 'ready' && session.state === 'preparing') {
        session.state = 'recording';
        this.changed(session.state, session.terminal);
      } else if (event.type === 'error' && typeof event.message === 'string') {
        return this.fail(session, event.message.slice(0, 1000));
      } else if (event.type === 'final' && typeof event.text === 'string' && session.state === 'stopping') {
        const text = terminalText(event.text);
        if (Buffer.byteLength(text, 'utf8') > 65536) return this.fail(session, 'Dictation exceeded the size limit for this version.');
        const validTarget = this.vscode.window.activeTerminal === session.terminal && this.vscode.window.terminals.includes(session.terminal);
        if (!validTarget) return this.cancel('Dictation cancelled: the original terminal is no longer active.');
        this.finish(session);
        if (!text) return void this.vscode.window.showInformationMessage('No speech recognized. Check the microphone and language.');
        try {
          session.terminal.sendText(text, false);
          session.terminal.show(true);
          void this.vscode.window.setStatusBarMessage('VozTTY: text inserted. Review before sending.', 5000);
        } catch {
          // Preserve a failed delivery in a VS Code document, without using the clipboard.
          void this.vscode.workspace.openTextDocument({ content: text, language: 'plaintext' }).then(doc => this.vscode.window.showTextDocument(doc));
          void this.vscode.window.showErrorMessage('Could not insert into the terminal. Your text was opened in a document for recovery.');
        }
      } else {
        return this.fail(session, 'Unexpected recognition event. Dictation was cancelled.');
      }
    }
  }

  fail(session, message) {
    if (this.session !== session) return;
    this.finish(session);
    void this.vscode.window.showErrorMessage(message);
  }

  finish(session) {
    if (this.session !== session) return;
    this.session = undefined;
    clearTimeout(session.timer);
    this.changed('idle', session.terminal);
    if (session.child && session.child.exitCode === null && !session.child.killed) {
      // The helper handles SIGTERM with cleanup; a pipe write after its final event can raise SIGPIPE in VS Code.
      session.child.kill('SIGTERM');
      const kill = setTimeout(() => { if (session.child.exitCode === null) session.child.kill('SIGKILL'); }, 2000);
      kill.unref();
      session.child.once('close', () => clearTimeout(kill));
    }
  }

  cancel(message) {
    if (!this.session) return;
    this.finish(this.session);
    if (message) void this.vscode.window.showInformationMessage(message);
  }

  dispose() { this.cancel(); }
}

module.exports = { Dictation, terminalText };
