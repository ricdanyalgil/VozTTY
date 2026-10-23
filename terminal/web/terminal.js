'use strict';
const term = new Terminal({
  fontFamily: 'SFMono-Regular, Menlo, Monaco, monospace', fontSize: 14, lineHeight: 1.3,
  allowProposedApi: true, cursorBlink: true, scrollback: 5000, screenReaderMode: true,
  theme: { background: '#000000', foreground: '#e6e6e6', cursor: '#eeeeee', cursorAccent: '#000000', selectionBackground: '#343434',
    black: '#161616', red: '#f08080', green: '#a8d5a2', yellow: '#e6cf91', blue: '#9dbbea',
    magenta: '#c6a8df', cyan: '#91cccc', white: '#dedede', brightBlack: '#858585', brightRed: '#ffaaaa',
    brightGreen: '#c3e8b5', brightYellow: '#f4e2ae', brightBlue: '#b7d1f4', brightMagenta: '#dfc4ee', brightCyan: '#b4e5e5', brightWhite: '#ffffff' }
});
const fit = new FitAddon.FitAddon();
let accents = [];
let accentFrame;
function scheduleAccents() {
  if (accentFrame !== undefined) return;
  accentFrame = requestAnimationFrame(() => {
    accentFrame = undefined;
    for (const {decoration, marker} of accents) { decoration.dispose(); marker.dispose(); }
    accents = [];
    const buffer = term.buffer.active;
    const rows = promptRows(buffer, buffer.viewportY, Math.min(buffer.length, buffer.viewportY + term.rows));
    for (const row of rows) {
      const marker = term.registerMarker(row - buffer.baseY - buffer.cursorY);
      if (!marker) continue;
      const decoration = term.registerDecoration({marker, width: term.cols, backgroundColor: '#081522', foregroundColor: '#a9d2ff', layer: 'bottom'});
      if (decoration) accents.push({decoration, marker});
      else marker.dispose();
    }
  });
}
const send = body => window.webkit.messageHandlers.terminal.postMessage(body);
const voicePanel = document.getElementById('voice-panel');
const voiceStatus = document.getElementById('voice-status');
const voiceHint = document.getElementById('voice-hint');
const voiceTime = document.getElementById('voice-time');
const pauseButton = document.getElementById('voice-pause');
const stopButton = document.getElementById('voice-stop');
const voiceBars = Array.from({length: 7}, () => document.getElementById('voice-wave').appendChild(document.createElement('span')));
document.getElementById('voice-cancel').addEventListener('click', () => send({type: 'cancelVoice'}));
pauseButton.addEventListener('click', () => send({type: 'pauseVoice'}));
stopButton.addEventListener('click', () => send({type: 'voice'}));
term.loadAddon(fit);
term.open(document.getElementById('terminal'));
term.onWriteParsed(scheduleAccents);
term.onScroll(scheduleAccents);
term.buffer.onBufferChange(scheduleAccents);
term.onData(data => send({type: 'input', data}));
term.onResize(({cols, rows}) => { send({type: 'resize', columns: cols, rows}); scheduleAccents(); });
term.onTitleChange(title => send({type: 'title', title}));
term.attachCustomKeyEventHandler(event => {
  if (event.type === 'keydown' && event.ctrlKey && event.altKey && event.code === 'KeyV') {
    send({type: 'voice'}); return false;
  }
  if (event.type === 'keydown' && event.key === 'Escape' && document.body.dataset.dictating === 'true') {
    send({type: 'cancelVoice'}); return false;
  }
  return true;
});
window.voz = {
  write(base64) { term.write(Uint8Array.from(atob(base64), c => c.charCodeAt(0))); },
  insert(text) { term.paste(text); term.focus(); },
  focus() { term.focus(); },
  state(state) {
    document.body.dataset.dictating = String(state !== 'idle');
    voicePanel.hidden = state === 'idle';
    voicePanel.dataset.state = state;
    const labels = {
      idle: '', preparing: 'Preparing microphone…', recording: 'Listening to you',
      pausing: 'Pausing…', paused: 'Recording paused', resuming: 'Resuming…', stopping: 'Transcribing on your Mac…'
    };
    voiceStatus.textContent = labels[state] ?? '';
    voiceHint.textContent = state === 'paused' ? 'Audio preserved. Continue when you are ready.'
      : state === 'stopping' ? 'Your text will appear in the prompt. Nothing is sent.'
      : state === 'preparing' ? 'Wait for Listening before speaking.'
      : 'Speak freely. Text appears after Stop & insert.';
    pauseButton.textContent = state === 'paused' ? 'Continue' : 'Pause';
    pauseButton.disabled = !['recording', 'paused'].includes(state);
    pauseButton.setAttribute('aria-pressed', String(state === 'paused'));
    stopButton.disabled = !['recording', 'paused'].includes(state);
    for (const bar of voiceBars) bar.style.height = '4px';
    if (state === 'preparing' || state === 'idle') voiceTime.textContent = '0:00';
  },
  meter(level, seconds) {
    if (voicePanel.dataset.state !== 'recording' || !Number.isFinite(level) || !Number.isFinite(seconds)) return;
    const value = Math.max(0, Math.min(1, level));
    voiceBars.forEach((bar, i) => { bar.style.height = `${4 + value * (32 - Math.abs(i - 3) * 5)}px`; });
    const total = Math.max(0, Math.floor(seconds));
    voiceTime.textContent = `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
  },
  screen() {
    const buffer = term.buffer.active;
    return Array.from({length: buffer.length}, (_, i) => buffer.getLine(i)?.translateToString(true) ?? '').join('\n');
  }
};
new ResizeObserver(() => fit.fit()).observe(document.getElementById('terminal'));
fit.fit();
send({type: 'ready', columns: term.cols, rows: term.rows});
term.focus();
