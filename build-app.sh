#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release --build-path bin
APP="TrackMyCursor.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "bin/release/TrackMyCursor" "$APP/Contents/MacOS/TrackMyCursor"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>TrackMyCursor</string>
    <key>CFBundleIdentifier</key><string>com.trackmycursor.TrackMyCursor</string>
    <key>CFBundleName</key><string>Track My Cursor</string>
    <key>CFBundleDisplayName</key><string>Track My Cursor</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
echo "Built $APP"
