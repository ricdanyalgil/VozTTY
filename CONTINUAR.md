# VozTTY checkpoint — 2026-10-23

## Publication authorization

The maintainer explicitly authorized making the repository public and publishing both the VS Code extension and the native terminal on GitHub. Earlier instructions to keep development private have been superseded. Public release v0.2.1 is published (not draft), with Terminal 0.2.1 and extension 0.1.2. Repository visibility was verified PUBLIC. All three release assets and the English README were downloaded without authentication and matched the local files. Release: https://github.com/ricdanyalgil/VozTTY/releases/tag/v0.2.1 . This is a public prerelease; the VS Code Marketplace was not used.

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

The maintainer requested removal of duplicate header window controls. Only standard macOS title-bar controls remain. Native 0.2.1 adds readable spoken-language names, shorter hints and clearer voice actions while preserving language IDs/preferences. VS Code stays at 0.1.2. Native 0.2.1 is installed and published. All release assets were downloaded anonymously and matched the local files. v0.2.0 artifacts and open sessions were preserved.

## Native 0.2.2 source follow-up

In-terminal real microphone level bars, audio duration and Pause/Continue controls are implemented. Transcription remains after Stop, with no automatic Enter. The helper emits metering/pause events only with the native client's opt-in --meter flag, preserving the VS Code protocol. The 0.2.1 public release assets and VS Code 0.1.2 are unchanged. See terminal/README.md for the voice-controls integration mode.

## Native 0.2.3 source follow-up

The voice panel now has a full-width continuous 20-second intensity history with paused intervals marked, replacing the seven instantaneous bars. All history is held briefly in memory and cleared on completion/cancel. Reduced motion avoids continuous scrolling. The native recognition protocol is unchanged from 0.2.2. Public release assets remain 0.2.1.

0.2.3 is installed locally. After the maintainer authorized the microphone in macOS, the physical-microphone voice-controls recheck passed: 99 real meter events, continuous history reacting to audio, pause excluding speech while preserving the audio on both sides, Stop while paused, and exact transcript insertion without Return. The earlier authorization wait is resolved. Synthetic waveform/layout validation also passed. No further X posts were created after the maintainer asked to stop.

## Native 0.2.4 compact voice line

Replaced the large voice card with a transparent, borderless 40 px line: muted monospace status/duration, a 28 px continuous waveform, and small text controls with 40 px targets. Recent 20-second history and pause markers remain. Narrow-window styles truncate only the status text. Recognition and pause behavior are unchanged. Public release assets still remain 0.2.1.

## Shared vocabulary — Terminal 0.2.5 / extension 0.1.3

Added a shared local `~/Library/Application Support/VozTTY/vocabulary.txt` file, loaded before each capture by the speech helper. This normalizes final text; it does not train or bias Apple's SpeechTranscriber. Native app menu (Command-comma) and VS Code Command Palette open the same file. Defaults contain assistant/product names only; personal project entries are local and must not be committed. Empty file disables correction. Invalid files fail before microphone capture.

Validation: 16 JavaScript tests, native vocabulary assertions and existing real-PTY/no-Enter checks pass. Synthetic English audio returned “Claude Code, Codex, Gemini, Blue Off.” The explicit Cloud Code alias works; Blue Auth remains an acoustic-recognition limitation unless its observed alternatives are registered. No new natural-voice/microphone or GUI verification. Native and VSIX builds pass. Public releases and Marketplace unchanged.

## Public preview 0.2.6 — discovery and waveform follow-up

The maintainer authorized implementing the repository-discovery plan and then requested larger waves. Native 0.2.6 gives the waveform its own full-width 42 px row, keeping transparent/borderless styling and compact actions. Layout tests passed 620–1440 px with zero overflow. Installed app is updated without closing working sessions.

Repository description and 12 relevant topics updated. Generated cover (`assets/social-preview.png`, 1280 × 640, <1 MB) and a 20-second edited GIF are in the English README. The GIF uses actual app captures and synthetic file input through the real Apple recognizer via an adapter confined to an owned temporary demo app; it does not open a microphone or connect an assistant. The shipping app/helper were not replaced by that adapter. A fresh speaker-to-microphone attempt failed to capture the intended playback; none of those frames/transcripts are public assets. Native public package is 0.2.6; extension 0.1.3. Release checksum verification is required before reporting publication.

Baseline traffic captured locally in work/github-growth-baseline.json: 0 views, 0 clones and no referrers; repo had 0 stars and 0 forks. No ongoing monitoring was scheduled. Community copy is prepared as drafts in docs/LAUNCH_KIT.md; no additional X/community posts made.

Social preview upload: Chrome is authenticated and the repository Settings page is open, but native browser controls repeatedly fail with noWindowsAvailable/offscreen errors. Generated cover is ready; do not claim the GitHub social preview has been applied without verification. The in-app browser is signed out.

Publication verified: https://github.com/ricdanyalgil/VozTTY/releases/tag/v0.2.6 is public and marked prerelease, with native ZIP 0.2.6, extension VSIX 0.1.3, demo MP4 and SHA256SUMS. All three assets were downloaded without authentication and matched the published checksums. Both packaged helpers match the production helper; native package signature verified. Native 0.2.6 is installed, without restarting user sessions. Social-preview upload remains pending due browser-control failures, despite authenticated Chrome. A larger-wave synthetic visual proof is saved outside the repo in outputs/voztty-larger-wave-preview.png. Owned test windows are cleaned up at task completion.

## Social preview completed

The generated 1280 × 640 cover was uploaded through authenticated GitHub Settings. GitHub GraphQL confirms `usesCustomOpenGraphImage: true`, and the public repository image was visually verified. This resolves all earlier social-preview-upload pending notes. No app code changed.

## Community setup

The maintainer requested continued improvements to the pasted GitHub General Settings screen. Enabled Discussions (default Announcements, General, Ideas, Polls, Q&A, Show and tell categories), added English bug/improvement issue forms, a question/install contact chooser and a pull request template, and linked community entry points from README/CONTRIBUTING. Forms were parsed as YAML and checked for required metadata/unique field IDs. No application, release, merge-policy, security, sponsorship or visibility changes.

## Terminal 0.2.7 — 2026-10-26

Finder file drops insert shell-escaped paths (`terminal/web/drop-paths.js`, `DropWebView` in App.swift) so CLIs attach images/audio/PDFs; no Enter. Top-bar language picker and Dictate hide while dictating; the top Cancel button was removed. UI labels follow the dictation language. Verified: 18 JS tests, harness `drop` and `layout` modes. Not verified: promised-file drags (browser images) and a live attach inside Claude Code/Codex. Installed by swapping the /Applications bundle; old 0.2.6 kept in the session scratchpad. Release v0.2.7 published and checksums verified from a fresh download.
