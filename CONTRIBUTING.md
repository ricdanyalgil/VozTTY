# Contributing to VozTTY

The current scope is the macOS VS Code terminal extension and the first standalone Mac terminal. Keep changes focused on dictation quality, terminal compatibility and a clear recording lifecycle.

Build the native helper with `./build-helper.sh` and run `npm test` on an Apple Silicon Mac. For UI and native integration changes, also test the installed VSIX in VS Code; unit tests do not validate microphone permissions or a CLI's actual input behavior.

Preserve these input guarantees: no clipboard access, no automatic Enter, no clearing existing prompt text, and no delivery to a different terminal after a recording starts.

When reporting a bug, include macOS/VS Code versions, language, assistant CLI and reproduction steps. Do not attach private recordings, credentials or sensitive transcripts to a public issue. A synthetic example is preferable when it reproduces the problem.

Build the standalone terminal with `./terminal/build.sh`; see `terminal/README.md` for native checks. Preserve the upstream licenses of the vendored renderer. Test-only hooks must remain excluded from normal builds.

Discuss new platforms, tabs, profiles or other architecture expansion in an issue before adding it. Development remains private until the maintainer approves publication.
