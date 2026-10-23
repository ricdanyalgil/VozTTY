# Contributing to VozTTY

Thank you for considering a contribution. We would be delighted to have you help make speaking to a terminal feel natural, reliable and easy to use.

## Ways to help

- Report a reproducible bug or share an accessibility issue.
- Improve installation instructions, examples or documentation.
- Test recognition languages, microphones and assistant CLI compatibility.
- Submit a focused fix with a clear explanation and relevant checks.

You do not need to be an experienced Swift developer to contribute. Documentation fixes and careful bug reports are valuable too.

## Before you start

Ask setup questions and share early ideas in [Discussions](https://github.com/ricdanyalgil/VozTTY/discussions). For reproducible bugs or concrete improvements, use the [issue forms](https://github.com/ricdanyalgil/VozTTY/issues/new/choose). Check existing issues, then open an issue for larger features or architectural changes. The current scope is the macOS VS Code extension and the standalone Mac terminal. Please discuss new platforms, tabs, profiles or cloud transcription before implementing them.

Keep communication respectful and give other contributors enough context to reproduce your findings.

## Set up and verify

Use an Apple Silicon Mac running macOS 26+, Apple's development tools and Node.js 22+.

```sh
git clone https://github.com/ricdanyalgil/VozTTY.git
cd VozTTY
npm test
./build-helper.sh
./terminal/build.sh
```

There are no npm production dependencies. For native unit and integration checks, see [terminal/README.md](terminal/README.md). UI changes should be checked at wide and narrow window sizes. Changes to dictation also need relevant testing with a real microphone or the real recognition engine; unit tests do not prove hardware behavior.

## Input guarantees

Preserve these behaviors:

- No clipboard round trip for dictation.
- No automatic Enter or execution of the dictated prompt.
- No clearing existing input or redirecting a result to a different terminal.
- Clear recording, stopping, cancellation and recovery states.
- No transcript, audio or credential logging.

Keep test-only hooks out of normal application builds. Preserve the upstream licenses of bundled dependencies.

## Send a pull request

1. Fork the repository and create a focused branch.
2. Make the smallest complete change that addresses the issue.
3. Run the relevant checks and describe what you tested.
4. Include a screenshot for a visible change and explain any known limit.
5. Open a pull request describing the problem and the resulting behavior.

By submitting a contribution, you agree that your contribution may be distributed under this project's MIT license.

## Report a bug safely

Include your macOS and VS Code versions, CPU architecture, recognition language, assistant CLI/version, reproduction steps and expected/observed behavior. For a regression, mention the last version that worked.

Please do not upload credentials, personal recordings, private prompts or sensitive screenshots. A short synthetic example is usually enough.

We appreciate your time and look forward to building with you.
