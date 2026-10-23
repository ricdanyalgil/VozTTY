# VozTTY checkpoint — 2026-10-23

## Publication authorization

The maintainer explicitly authorized making the repository public and publishing both the VS Code extension and the native terminal on GitHub. Earlier instructions to keep development private have been superseded. Public release v0.2.0 is published (not draft), with Terminal 0.2.0 and extension 0.1.2. Repository visibility was verified PUBLIC. All three release assets and the English README were downloaded without authentication and matched the local files. Release: https://github.com/ricdanyalgil/VozTTY/releases/tag/v0.2.0 . This is a public prerelease; the VS Code Marketplace was not used.

## Current products

- Native Mac terminal: black layout, blue prompt accents, standard macOS title-bar controls, corrected grid sizing and app icon. Installed in /Applications/VozTTY.app.
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

## Native 0.2.1 follow-up

The maintainer requested removal of duplicate header window controls. Only standard macOS title-bar controls remain. Native 0.2.1 adds readable spoken-language names, shorter hints and clearer voice actions while preserving language IDs/preferences. VS Code stays at 0.1.2. Prepare and verify the native update and its public patch release without overwriting v0.2.0 artifacts or interrupting open sessions.
