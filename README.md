# VozTTY

**Speak your next prompt. Stay in your terminal.**

VozTTY adds a microphone button to VS Code's terminal toolbar. Record a dictation, stop, and the transcript is inserted directly into the terminal prompt — no clipboard, no separate transcription window, and no automatic Enter.

[Português](README.pt-BR.md) · [Download](https://github.com/ricdanyalgil/VozTTY/releases) · [Report an issue](https://github.com/ricdanyalgil/VozTTY/issues)

**Experimental, macOS-only.** The first release is a VS Code extension. A standalone Mac terminal is planned for a later stage; it is not included in this release.

## What it does

- Adds a microphone button to the integrated terminal, including terminals opened as editor tabs.
- Uses Apple's on-device SpeechAnalyzer / SpeechTranscriber through a small Swift helper.
- Preserves punctuation and accents; removes terminal control characters and collapses line breaks into spaces.
- Binds a recording to its original terminal. Switching or closing terminals cancels the dictation.
- Inserts the final transcript once, without appending Enter. Existing prompt text is not cleared.
- Supports `pt-BR`, `pt-PT` and `en-US`, subject to Apple's device and language availability.

The initial delivery was built for prompts in Claude Code, Codex CLI and Gemini CLI. Compatibility with their real interactive input fields still needs hands-on validation; a passing terminal API test is not proof of compatibility with every CLI.

## Requirements

- VS Code desktop 1.93 or later; tested on 1.142.0.
- Apple Silicon Mac with macOS 26 or later; tested on macOS 27.
- Microphone permission. Apple may need to download a language model on first use.

The extension runs in VS Code's local UI extension host. Remote SSH/Container behavior has not yet been validated. VS Code in a browser, Intel Macs, Windows and Linux are not supported by this release.

## Install

1. Download the `.vsix` file from [Releases](https://github.com/ricdanyalgil/VozTTY/releases).
2. In VS Code, open **Extensions → … → Install from VSIX…** and select the file.
3. Open the integrated terminal. If the microphone does not appear, run **Developer: Reload Window** when convenient.

The extension identifier remains `danyalgil.voz-terminal`, so existing local installations and settings can be retained. This project has not been published to the VS Code Marketplace.

## Use

1. Select the terminal where you want to write.
2. Click the microphone in the terminal toolbar, or press **Control + Option + V**.
3. Wait for the recording indicator, then speak.
4. Click Stop, or use the same shortcut. The final transcript appears in the prompt.
5. Review, edit and send it yourself.

**Escape** cancels while the terminal is focused. During preparation or transcription, the status bar indicator can also cancel. Choose a language in **Settings → Voz: Language**; the default is Brazilian Portuguese.

This release inserts text **after you stop recording**. It does not show a live word-by-word transcript.

## Privacy and input behavior

VozTTY does not use a cloud transcription API, access assistant credentials, or read/write the clipboard. Audio is temporarily recorded in a private directory and deleted after normal completion or cancellation. A forced shutdown can leave a temporary recording behind. There is no persistent transcript history.

Only the final text is sent to the terminal's input stream. The extension does not know which internal field a CLI currently has focused. Use it in a text prompt: a program that reacts immediately to individual characters may react to dictated text even without Enter.

Transcription has a 60-second timeout after Stop and a 64 KiB final-text limit. The native helper is locally ad hoc signed, not notarized for public distribution. See [the Portuguese guide](README.pt-BR.md) for additional details.

## Build from source

Use an Apple Silicon Mac, Node.js 22 or later, and Apple's development tools with the macOS 26 SDK or later.

```sh
git clone https://github.com/ricdanyalgil/VozTTY.git
cd VozTTY
./build-helper.sh
npm test
npx @vscode/vsce package --no-dependencies --target darwin-arm64
```

The extension has no npm production dependencies. Apple's frameworks and language models are provided by the operating system, not bundled in this repository. `build-helper.sh` builds and signs the helper outside synced Documents folders before copying it into the extension.

## Validation

Nine automated tests cover text handling, terminal targeting, cancellation, malformed responses and process failures. A VS Code Extension Development Host test also passed using a synthetic Portuguese recording, the real Apple transcription engine and a test pseudo-terminal. It verified a single insertion without Return or Escape characters, including with the installed VSIX contents.

The microphone button was observed in a running VS Code window. Real microphone capture, denied permissions, actual input in each assistant CLI, remote workspaces and long-dictation resource use remain to be tested.

`test/integration.js` is the Extension Development Host test entrypoint. It requires `VOZ_TEST_AUDIO` pointing to a synthetic speech file; `VOZ_TEST_RESULT` optionally writes the test result. It does not open the microphone or execute shell commands in the test terminal.

## Next stage

First validate the VS Code experience with real speech and the three CLI assistants. Then evaluate a standalone Mac terminal that reuses the voice component and an existing terminal-emulation library.

## Contributing and license

See [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under [MIT](LICENSE).
