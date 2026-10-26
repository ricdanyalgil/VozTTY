'use strict';
// Links, paths and document names get their own colour so they stand out from prose.
// shortcut: per-row regexes, so a path wrapped onto the next row is only coloured on its first row.
const TOKENS = [
  ['url', /\bhttps?:\/\/[^\s<>"'`)\]]+[^\s<>"'`)\].,;:!?]/gu],
  // Absolute, home and relative paths, including Terminal-style escaped spaces ("My\ File.pdf").
  ['path', /(?<![\w/])(?:~|\.{1,2})?\/(?:\\ |[^\s"'`<>()|])*(?:\\ |[^\s"'`<>()|.,;:!?])/gu],
  // Relative paths such as test/drop-paths.test.js are recognised by their file extension.
  ['file', /(?<![\w/.-])[\p{L}\p{N}_-][\p{L}\p{N}_./-]*\.(?:pdf|docx?|xlsx?|pptx?|csv|txt|md|json|ya?ml|png|jpe?g|gif|svg|mp4|mov|opus|m4a|mp3|wav|zip|py|js|ts|tsx|swift|html|css|sh)\b/giu],
];
function textTokens(text) {
  const found = [];
  for (const [kind, pattern] of TOKENS) {
    for (const match of text.matchAll(pattern)) {
      const start = match.index, end = start + match[0].length;
      // A URL contains a path and a path ends in a file name: keep the first, widest match.
      if (!found.some(t => start < t.end && end > t.start)) found.push({kind, start, end});
    }
  }
  return found.sort((a, b) => a.start - b.start);
}
if (typeof module !== 'undefined') module.exports = textTokens;
