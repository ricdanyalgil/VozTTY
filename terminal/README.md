# VozTTY Terminal — private native preview

A single-session Mac terminal with a microphone in its own window. Uses AppKit, a bundled xterm.js renderer in WKWebView, a real PTY and the shared local speech helper. Apple Silicon and macOS 26+ only.

## Build and open

From the repository root, with Apple's development tools installed:

```sh
./terminal/build.sh
open terminal/VozTTY.app
```

The renderer is vendored with its upstream licenses. There is no Node.js runtime, package installation or CDN dependency in the app. `-- /absolute/executable [arguments...]` starts an executable directly; otherwise the app starts `/bin/zsh -l`. The working directory is inherited, or the home directory when started from `/`.

Click **Dictate**, wait for **Recording**, speak, then **Stop & insert**. The shortcut is **Control + Option + V** while the terminal is focused. **Esc** cancels. Select a language from the toolbar. Dictation is passed through xterm.js's paste path, including bracketed paste when the child application requests that mode. It never appends Return.

The header includes persistent Minimize, Maximize/restore and Close controls in addition to the standard macOS title bar. Close uses the existing active-session confirmation.

This preview has one window/session. No tabs, splits, session restoration, configurable profiles or notarization yet. Closing a running shell asks for confirmation. Closing the app loses unsent terminal text and unsaved recovery windows.

## Conversation layout

The black terminal keeps questions in soft blue (`#a9d2ff`) on a subtle dark-blue background, with ordinary output in neutral light gray. The header groups app identity and microphone status; the footer separates the color legend from keyboard shortcuts. Terminal control sequences and clipboard contents are not rewritten to apply colors.

Visual accents recognize lines starting with `›`, `❯` or `>` followed by whitespace, including their automatic line wraps. This covers the tested Codex, Claude Code and Antigravity prompts. It is a visual cue, not role metadata: a quoted output line using the same prefix can also be blue, and explicit multiline continuations without a prefix may keep their CLI colors. ANSI colors in other output are preserved. The renderer scans only the visible rows and refreshes accents on redraw, scroll and resize.

## Unit checks

From the repository root:

```sh
xcrun swiftc -parse-as-library -swift-version 6 \
  test/terminal.unit.swift terminal/PTY.swift terminal/Dictation.swift \
  -o /tmp/voztty-terminal-unit
/tmp/voztty-terminal-unit
```

`npm test` also checks prompt recognition, wrapping, Unicode and reused rows.

Checks terminal control removal, preserved Unicode/punctuation, a real child PTY, resize and the difference between a draft and explicitly submitted input.

## Integration harness

`test/terminal.integration.swift` is compiled only with `-D VOZ_TEST` and is excluded from the normal app. Compile it with the four Swift files in this directory, place that executable in a temporary copy of the built app, and ad hoc sign the copy before running it. Do not replace the installed application with the test executable.

The harness requires `VOZ_TEST_RESULT`. Modes:

- `VOZ_TEST_MODE=layout`: resizes the native window through 1120, 620, 800 and 1440 px widths, checks completed grid fitting and ensures no right/bottom overflow. Requires no model login or microphone.
- `VOZ_TEST_MODE=inspect`: records startup metadata and optional local `VOZ_TEST_SCREEN`; does not insert a prompt.
- `VOZ_TEST_MODE=cli`: requires `VOZ_TEST_READY` (an input-composer regex) and `VOZ_TEST_TRANSCRIPT` (a test transcript path). Inserts an existing prefix and a long transcript, then verifies the PTY bytes and the visible draft without Enter.
- `VOZ_TEST_MODE=long-microphone`: additionally requires `VOZ_TEST_PHRASE` pointing to `test/fixtures/long-dictation.txt` and `VOZ_TEST_TRANSCRIPT` as the output path. Opens the real microphone and plays synthetic Portuguese speech through the current speakers. Checks opening/closing coverage, capture/file duration, draft insertion and no Return.

`VOZ_TEST_KEEP_OPEN=1` leaves the test window open for visual inspection. Other runs close their own test window when complete. Tests never submit a prompt to a model. Text/screen evidence stays local unless deliberately selected for the documentation; do not commit personal dictations or account details.

The Claude setup helper can confirm trust only when `VOZ_TEST_TRUST_DISPOSABLE=1` and the working directory is empty and named `/tmp/voztty-workspace.*`. Gemini setup remains untrusted. Authentication is never bypassed or supplied by the harness.

## VS Code CLI checks

`test/cli.integration.js` runs through the Extension Development Host, with the actual installed extension, actual CLI processes and a test PTY. It requires `VOZ_TEST_AUDIO`, `VOZ_TEST_RESULT`, `VOZ_TEST_HEADLESS` (an isolated `@xterm/headless` 6.0.0 package path), and `VOZ_TEST_CODEX` / `VOZ_TEST_CLAUDE` executable paths. The speech input is a local synthetic audio file; this test does not open the microphone. The headless renderer is test-only and is not a production dependency.

Read [the validation record](../VALIDACAO.md) before interpreting any test as compatibility or recognition-accuracy evidence.

## App icon

The editable vector is `assets/voztty-icon.svg`. Run `./terminal/build-icon.sh` from the repository root after editing it, then rebuild the app. This asset-only task uses ImageMagick plus macOS sips/iconutil. It exports standard/Retina sizes and checks the terminal glyph before and after ICNS conversion. The glyph uses filled shapes because the previous stroke-based SVG lost its symbol in the converter. ImageMagick is not needed to run the app.
