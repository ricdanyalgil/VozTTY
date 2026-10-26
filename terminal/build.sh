#!/bin/zsh
set -euo pipefail
cd -- "${0:A:h}"
stage=$(mktemp -d "${TMPDIR:-/tmp}/voztty-terminal.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
app="$stage/VozTTY.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
../build-helper.sh
xcrun swiftc -parse-as-library -swift-version 6 -O -target arm64-apple-macos26.0 Main.swift App.swift PTY.swift Dictation.swift ../native/Vocabulary.swift -o "$app/Contents/MacOS/VozTTY" -framework AppKit -framework WebKit
cp -R web "$app/Contents/Resources/web"
cp VozTTY.icns "$app/Contents/Resources/VozTTY.icns"
cp ../LICENSE "$app/Contents/Resources/LICENSE"
ditto --norsrc --noextattr ../native/VozEngine.app "$app/Contents/Resources/VozEngine.app"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>VozTTY</string>
<key>CFBundleIdentifier</key><string>com.danyalgil.voztty.terminal</string>
<key>CFBundleName</key><string>VozTTY</string>
<key>CFBundleIconFile</key><string>VozTTY.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.8</string>
<key>CFBundleVersion</key><string>10</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppleEventsUsageDescription</key><string>Programs you run in VozTTY, such as AI agents, can automate other apps when you allow it.</string>
<key>NSMicrophoneUsageDescription</key><string>VozTTY captures speech only when you start dictation and inserts the transcript into your terminal without pressing Enter.</string>
</dict></plist>
PLIST
xattr -cr "$app"
# A stable identity keeps macOS privacy grants (microphone, Accessibility, Screen Recording) across updates;
# ad hoc signatures lose them on every build. Example: VOZTTY_SIGN="Developer ID Application: …" ./terminal/build.sh
sign=${VOZTTY_SIGN:--}
codesign --force --sign "$sign" "$app/Contents/Resources/VozEngine.app"
codesign --force --sign "$sign" "$app"
codesign --verify --deep --strict "$app"
ditto --norsrc --noextattr "$app" "$PWD/VozTTY.app"
print "Built: $PWD/VozTTY.app"
