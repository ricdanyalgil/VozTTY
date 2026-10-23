#!/bin/zsh
set -euo pipefail
cd -- "${0:A:h}"
# Sign outside synced Documents, where Finder metadata can appear during signing.
stage=$(mktemp -d "${TMPDIR:-/tmp}/voz-engine.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
app="$stage/VozEngine.app"
mkdir -p "$app/Contents/MacOS"
xcrun swiftc -parse-as-library -swift-version 6 -O -target arm64-apple-macos26.0 native/VoiceEngine.swift native/Vocabulary.swift -o "$app/Contents/MacOS/VozEngine" -framework AppKit -framework AVFoundation -framework Speech
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>VozEngine</string>
<key>CFBundleIdentifier</key><string>com.danyalgil.voz.vscode.engine</string>
<key>CFBundleName</key><string>Voz Engine</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSUIElement</key><true/>
<key>NSMicrophoneUsageDescription</key><string>VozTTY records speech when you click the microphone and inserts it into the terminal where dictation started.</string>
<key>NSSpeechRecognitionUsageDescription</key><string>VozTTY recognizes speech locally on this Mac to insert text into your selected terminal.</string>
</dict></plist>
PLIST
xattr -cr "$app"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
ditto --norsrc --noextattr "$app" "$PWD/native/VozEngine.app"
