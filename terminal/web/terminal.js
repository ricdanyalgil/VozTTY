'use strict';
const term = new Terminal({
  fontFamily: 'Menlo, Monaco, monospace', fontSize: 14, lineHeight: 1.22,
  cursorBlink: true, scrollback: 5000, screenReaderMode: true,
  theme: { background: '#111b22', foreground: '#e8f0f2', cursor: '#d8fc87', selectionBackground: '#405441',
    black: '#192832', red: '#ff8e86', green: '#d8fc87', yellow: '#f3d08a', blue: '#8dc7ff',
    magenta: '#d6afff', cyan: '#8cddd3', white: '#e8f0f2', brightBlack: '#8197a3', brightRed: '#ffa8a1',
    brightGreen: '#e3ffb1', brightYellow: '#ffe6ac', brightBlue: '#b2dcff', brightMagenta: '#ead0ff', brightCyan: '#b0eee6', brightWhite: '#ffffff' }
});
const fit = new FitAddon.FitAddon();
const send = body => window.webkit.messageHandlers.terminal.postMessage(body);
term.loadAddon(fit);
term.open(document.getElementById('terminal'));
term.onData(data => send({type: 'input', data}));
term.onResize(({cols, rows}) => send({type: 'resize', columns: cols, rows}));
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
  state(active) { document.body.dataset.dictating = String(active); },
  screen() {
    const buffer = term.buffer.active;
    return Array.from({length: buffer.length}, (_, i) => buffer.getLine(i)?.translateToString(true) ?? '').join('\n');
  }
};
new ResizeObserver(() => fit.fit()).observe(document.getElementById('terminal'));
fit.fit();
send({type: 'ready', columns: term.cols, rows: term.rows});
term.focus();
