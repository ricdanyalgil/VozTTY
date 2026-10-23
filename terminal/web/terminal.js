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
