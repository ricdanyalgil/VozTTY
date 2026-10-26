'use strict';
const PROMPT = /^ {0,2}[›❯>](?:\s|$)/u;
// Claude Code and Codex break long prompts themselves and indent the next rows by two spaces.
// Tree/box glyphs open tool output, not prompt text.
const CONTINUATION = /^ {2,}[^\s⎿│└├╰]/u;
function promptRows(buffer, start, end) {
  let first = start;
  for (let back = 0; first > 0 && back < 200; back++, first--) {
    const line = buffer.getLine(first);
    if (!line || !(line.isWrapped || CONTINUATION.test(line.translateToString(true)) || !line.translateToString(true).trim())) break;
  }
  const rows = [];
  let open = false, blanks = [];
  const keep = row => { if (row >= start) rows.push(row); };
  for (let row = first; row < end; row++) {
    const line = buffer.getLine(row);
    if (!line) break;
    // shortcut: prompt glyphs and indentation identify visual rows, use CLI role metadata if upstream provides it.
    const text = line.translateToString(true);
    if (line.isWrapped) { if (open) keep(row); continue; }
    if (PROMPT.test(text)) { open = true; blanks = []; keep(row); continue; }
    if (open && !text.trim()) { blanks.push(row); continue; }
    // A blank row stays inside the prompt only when indented prompt text follows it.
    if (open && CONTINUATION.test(text)) { blanks.forEach(keep); blanks = []; keep(row); continue; }
    open = false; blanks = [];
  }
  return rows;
}
if (typeof module !== 'undefined') module.exports = promptRows;
