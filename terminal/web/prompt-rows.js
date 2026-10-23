'use strict';
function promptRows(buffer, start, end) {
  let first = start;
  while (first > 0 && buffer.getLine(first)?.isWrapped) first--;
  const rows = [];
  let prompt = false;
  for (let row = first; row < end; row++) {
    const line = buffer.getLine(row);
    if (!line) break;
    // shortcut: prompt glyphs identify visual rows, use CLI role metadata if upstream provides it.
    if (!line.isWrapped) prompt = /^ {0,2}[›❯>](?:\s|$)/u.test(line.translateToString(true));
    if (prompt && row >= start) rows.push(row);
  }
  return rows;
}
if (typeof module !== 'undefined') module.exports = promptRows;
