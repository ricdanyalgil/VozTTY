# Changelog

## Public preview v0.2.1 — 2026-10-23

Native terminal update; the VS Code extension remains 0.1.2.

- Remove duplicate minimize/maximize/close buttons from the content header; keep the standard macOS title-bar controls.
- Show readable language names while preserving the recognition language IDs and saved preferences.
- Make Dictate easier to find, shorten the keyboard hints and clarify recording, cancellation and review guidance.

## Public preview v0.2.0 — 2026-10-23

This release includes two separate downloads: **VozTTY Terminal 0.2.0** and the **VS Code extension 0.1.2**.

### Native Mac terminal

- AppKit window, local WebKit/xterm.js renderer and real macOS PTY.
- Dictate/Stop & insert, cancellation and transcript recovery.
- Black conversation layout with blue prompt accents and light output.
- Persistent minimize, maximize/restore and close controls.
- Corrected terminal sizing during window resize and restored the app icon glyph.

### VS Code extension

- Microphone control in the integrated terminal, local Apple speech recognition and direct insertion without Enter.
- Original terminal targeting, cancellation on terminal switch/close and recovery on delivery failure.
- Closed-pipe shutdown fix from 0.1.1.
- English command names, status messages, error messages and permission descriptions in 0.1.2. Command IDs remain unchanged.

### Validation and limits

- Twelve JavaScript unit checks and native PTY/resize checks passed locally.
- Maintainer confirmed short voice use in Codex, Claude Code and Antigravity in the native terminal.
- Long controlled acoustic and CLI insertion checks are documented in the README.
- Apple Silicon/macOS 26+ only. Packages are ad hoc signed, not notarized. This remains a preview.
