'use strict';
// Dropped files become shell-escaped paths, like Terminal.app. CLIs such as Claude Code and Codex attach images/PDFs from them.
function dropPaths(paths) {
  return paths
    // A name with control characters could end bracketed paste or inject keys; skip it rather than paste a wrong path.
    .filter(path => typeof path === 'string' && path.startsWith('/') && !/[\u0000-\u001f\u007f-\u009f]/.test(path))
    .map(path => path.replace(/[^\w\-.,/:@%+= -￿]/g, '\\$&'))
    .join(' ');
}
if (typeof module !== 'undefined') module.exports = dropPaths;
