# VozTTY checkpoint — 2026-10-23

## Publication authorization

The maintainer explicitly authorized making the repository public and publishing both the VS Code extension and the native terminal on GitHub. Earlier instructions to keep development private have been superseded. Public release target: v0.2.0, with Terminal 0.2.0 and extension 0.1.2. Verify live GitHub state before reporting publication complete.

## Current products

- Native Mac terminal: black layout, blue prompt accents, persistent window controls, corrected grid sizing and app icon. Installed in /Applications/VozTTY.app.
- Extension: English UI/messages in 0.1.2, stable command IDs and original no-Enter/no-clipboard behavior. Do not interrupt existing VS Code windows to update them.
- Main README, contribution guide and release notes are in English. Optional Portuguese documentation remains available.
- Both clients use the local Apple SpeechAnalyzer helper. Apple Silicon/macOS 26+ only; ad hoc signed, not notarized.

## Verified scope

Twelve JavaScript unit tests, native PTY/input checks, long draft insertion in assistant CLIs and window-fit checks. Maintainer confirmed short natural voice in Codex, Claude Code and Antigravity. Long controlled acoustic check: 82 seconds/182 words, not a perfect-accuracy claim or a completed long natural-voice test. Development details are in VALIDACAO.md.

## Remaining work

- Longer natural speech, fresh-install permissions, interruptions and remote terminals.
- Notarization and sustained native terminal use.
- Antigravity through the VS Code extension, beyond the completed native-terminal test.
- Do not log/upload recordings, credentials or personal prompts. Diagnostics in work/ are not release content.

## Before another release

Build both packages, inspect their contents, run relevant checks, prepare checksums and verify the public release assets. Keep third-party licenses. Reviewers should distinguish synthetic layout screenshots from actual assistant/recognition results. Do not publish to the VS Code Marketplace without a separate request.
