#!/bin/zsh
set -e
cd "$(dirname "$0")"
NAME="p16_level_devil"

odin build . -out:"$NAME"

# macOS .app bundle for keyboard focus
APP="/tmp/$NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$NAME" "$APP/Contents/MacOS/$NAME"
cat > "$APP/Contents/Info.plist" <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>dev.learn.$NAME</string>
  <key>CFBundleName</key><string>learn-$NAME</string>
  <key>CFBundleDisplayName</key><string>learn-$NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
open "$APP"
