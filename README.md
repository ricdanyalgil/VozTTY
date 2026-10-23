<p align="center"><img src="assets/voztty-icon.png" width="96" alt="VozTTY terminal icon" /></p>
<h1 align="center">VozTTY</h1>
<p align="center"><strong>Speak your next prompt.</strong><br />Local voice dictation for your Mac terminal and VS Code.<br />Speak freely. Review the text. Press Enter when you are ready.</p>

<p align="center">
  <a href="https://github.com/ricdanyalgil/VozTTY/releases/tag/v0.2.1"><img src="https://img.shields.io/github/v/release/ricdanyalgil/VozTTY?include_prereleases&amp;label=public%20preview&amp;style=flat" alt="Public preview release" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat" alt="MIT license" /></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-black?logo=apple&amp;style=flat" alt="macOS 26 or later" />
  <img src="https://img.shields.io/badge/Apple%20Silicon-arm64-555555?style=flat" alt="Apple Silicon arm64" />
  <img src="https://img.shields.io/badge/VS%20Code-1.93%2B-007ACC?style=flat" alt="VS Code 1.93 or later" />
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-78A641?style=flat" alt="Pull requests welcome" /></a>
</p>

<p align="center"><a href="#download-and-install">Download</a> · <a href="#two-ways-to-work">Features</a> · <a href="#compatibility-and-validation">Compatibility</a> · <a href="#build-from-source">Build</a> · <a href="#contributions-are-welcome">Contribute</a></p>

<img src="assets/terminal-conversation.png" width="1100" alt="VozTTY on Mac, with blue question prompts, light replies, microphone controls and keyboard shortcuts." />
<p align="center"><sub>The real native application displaying an English synthetic conversation to demonstrate the layout. This image is not a speech-accuracy benchmark or a model-generated answer.</sub></p>

## Your voice, where you already work

Explaining a task can be easier than typing it. VozTTY brings a microphone directly to your terminal so you can explain the context, add details and keep your train of thought.

**Click the microphone → speak → stop → review → send it yourself.**

- **Local speech recognition** through Apple's SpeechAnalyzer. No VozTTY cloud account or transcription API key.
- **Direct insertion** into your prompt, preserving existing text. No clipboard round trip.
- **No automatic Enter.** Dictation stays editable until you choose to send it.
- **Three recognition languages:** Brazilian Portuguese, European Portuguese and US English, subject to Apple's model availability.
- **Keyboard control:** <kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>V</kbd> starts/stops dictation; <kbd>Esc</kbd> cancels while the terminal has focus.

Text arrives **after you stop recording**. Word-by-word live transcription is not included.

## Two ways to work

| | VozTTY Terminal | VS Code extension |
| :--- | :--- | :--- |
| Where | A standalone native Mac application | Your existing integrated terminals |
| Voice controls | **Dictate / Stop & insert** in the header | Microphone and Stop icons in the terminal toolbar |
| Display | Black background, blue prompt accents and light output | Your VS Code terminal theme |
| Window | Standard macOS title-bar controls | Standard VS Code controls |
| Engine | AppKit, WebKit, xterm.js and a real macOS PTY | VS Code terminal API and a native Swift helper |
| Current package | **0.2.1** | **0.1.2** |

The Mac terminal currently supports one window/session per instance. Tabs, split panes and session restoration are on the roadmap.

## Download and install

**Requires an Apple Silicon Mac running macOS 26 or later.** VS Code integration additionally requires VS Code desktop 1.93+. Apple's speech models may require an initial download.

| Package | Download | Install |
| :--- | :--- | :--- |
| Mac terminal | [VozTTY Terminal 0.2.1 ZIP](https://github.com/ricdanyalgil/VozTTY/releases/download/v0.2.1/voztty-terminal-0.2.1-darwin-arm64.zip) | Extract and move **VozTTY.app** to **Applications** |
| VS Code extension | [VozTTY 0.1.2 VSIX](https://github.com/ricdanyalgil/VozTTY/releases/download/v0.2.1/voztty-0.1.2-darwin-arm64.vsix) | **Extensions → … → Install from VSIX…** |
| Integrity | [SHA256SUMS.txt](https://github.com/ricdanyalgil/VozTTY/releases/download/v0.2.1/SHA256SUMS.txt) | Verify with `shasum -a 256 -c SHA256SUMS.txt` in the download folder |

These are **public preview builds**, signed ad hoc and **not notarized by Apple**. macOS may require a manual security review before opening them. Building from source is also supported. The extension is distributed through GitHub Releases; it is not listed on the VS Code Marketplace yet.

### In the Mac terminal

Open **VozTTY**, then run your installed assistant as usual:

```sh
codex
# or
claude
# or
agy
```

Click **Dictate**, wait for **Listening**, speak, then choose **Stop & insert**. Read and edit the transcript before pressing Enter. Choose your spoken language by name in the header; the interface keeps window actions in the standard macOS title bar. The CLIs must be installed and authenticated separately; VozTTY does not bundle them or manage their accounts.

### In VS Code

Install the VSIX, open an integrated terminal and click its microphone icon. You can also run **VozTTY: Start Terminal Dictation** from the Command Palette. If the icon is missing, use **Developer: Reload Window** when it is safe to interrupt your window.

The extension ID remains `danyalgil.voz-terminal`. Set **Voz: Language** (`voz.language`) to `pt-BR`, `pt-PT` or `en-US`; the default is `pt-BR`. Switching or closing the source terminal cancels an active recording.

## Compatibility and validation

| Client / check | Verified behavior |
| :--- | :--- |
| Codex in VozTTY Terminal | Maintainer microphone test and long draft insertion |
| Claude Code in VozTTY Terminal | Maintainer microphone test and long draft/paste block insertion |
| Gemini through Antigravity (`agy`) | Maintainer microphone test and a 182-word draft retained without Enter |
| Claude Code and Codex in VS Code | Long synthetic audio recognized by the real Apple engine and inserted through the extension without Enter |
| Physical microphone, Mac terminal | Controlled 82-second recording, 182 recognized words, opening/closing and existing prefix preserved |
| Automated checks | 12 JavaScript unit tests; native PTY/input checks; window-fit regression from 620 to 1440 px |

Earlier acoustic runs lost words, and proper names can be misrecognized. The controlled long recording used speech played through speakers into the physical microphone. **It is an integration check, not a claim of perfect accuracy or a completed long test with the maintainer's natural voice.** Automated CLI tests leave prompts unsent; the maintainer separately confirmed real voice use in all three clients.

Google [moved personal-account terminal access to Antigravity CLI](https://github.com/google-gemini/gemini-cli/discussions/27274). Use `agy` for that workflow. Legacy Gemini CLI remains available with eligible enterprise or paid API access.

## How it works

```mermaid
flowchart LR
    A[Start dictation] --> B[Native Swift helper]
    B --> C[Microphone capture]
    C --> D[Apple SpeechAnalyzer]
    D --> E[Terminal-safe text]
    E --> F[VS Code terminal]
    E --> G[VozTTY PTY]
    F --> H[Review and press Enter yourself]
    G --> H
```

The native app uses AppKit, WKWebView, xterm.js 6.0.0 and a macOS pseudo-terminal. Its renderer is bundled locally with no CDN or Node.js runtime. The extension has no npm production dependencies. Both share the same Swift speech helper. Upstream [renderer licenses](terminal/web/vendor/README.md) are included.

### Privacy and current limits

- Voice recognition runs on the Mac. VozTTY has no cloud transcription backend, assistant credentials or persistent transcript history.
- Recordings use a private temporary folder and are removed on normal completion/cancellation. A forced shutdown can leave temporary audio behind.
- Terminal control characters are removed and line breaks become spaces. A program that reacts immediately to characters can still react without Enter; dictate into the intended text input.
- Transcription has a 60-second timeout **after Stop** and a 64 KiB text limit. Recording itself is not limited to 60 seconds.
- Native prompt colors recognize `›`, `❯` and `>` markers and automatic wraps. Output using the same markers may also be highlighted; explicit multiline continuations may retain their CLI colors.
- Closing the app ends running programs and loses unsent prompts or unsaved recovery text. An active session asks for confirmation.
- Intel Macs, Windows, Linux and browser-based VS Code are unsupported. Remote terminals and fresh-install permission failures need more validation.

## Build from source

Use an Apple Silicon Mac, Apple's development tools with the macOS 26 SDK or later, and Node.js 22+ for extension packaging/tests.

```sh
git clone https://github.com/ricdanyalgil/VozTTY.git
cd VozTTY
npm test

# Native terminal
./terminal/build.sh
open terminal/VozTTY.app

# VS Code extension
./build-helper.sh
npx @vscode/vsce@4.0.0 package --no-dependencies --target darwin-arm64 \
  --out voztty-0.1.2-darwin-arm64.vsix
```

No npm install is required for production dependencies. Native checks, test-only integration hooks and icon generation are described in [`terminal/README.md`](terminal/README.md).

## Contributions are welcome

**We would love to build VozTTY with you. It would be a pleasure to welcome your contribution.**

Bug reports, documentation improvements, accessibility feedback, recognition-language testing and pull requests are all welcome. First contribution? A small documentation fix or a reproducible bug report is a great place to start.

- Read the [contribution guide](CONTRIBUTING.md).
- [Report a bug or propose an idea](https://github.com/ricdanyalgil/VozTTY/issues).
- [Open a pull request](https://github.com/ricdanyalgil/VozTTY/pulls).
- Please use synthetic examples instead of private recordings or sensitive transcripts.

### Roadmap

- Longer tests with natural speech and more microphones/languages.
- Fresh-install permissions, interruption recovery and remote-terminal validation.
- Native terminal stability, accessibility and notarized distribution.
- Tabs and split panes after the single-session experience is solid.
- VS Code Marketplace distribution.

## License

VozTTY is open source under the [MIT license](LICENSE). Copyright © 2026 Ricardo Danyalgil Junior. Bundled third-party components retain their own licenses.
