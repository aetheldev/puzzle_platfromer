#!/bin/zsh
# Shared graphics-lesson runner.
#
# WHY THIS EXISTS:
# On macOS, a binary launched straight from the terminal runs as a background
# (Accessory) process. Its window can never become "key", so it never receives
# keyboard focus — your arrow keys end up typed into the terminal instead.
# The reliable fix is to wrap the binary in a real .app bundle and `open` it,
# which makes macOS treat it as a foreground GUI app that can grab focus.
#
# On Linux / Windows there is no such problem, so we just `odin run`.
#
# USAGE (from a lesson's build.sh):
#   source "<path-to>/run_graphics.sh"
#   run_graphics <app_name> <sokol_collection_path>
# where the caller has already `cd`-ed into the lesson directory.

run_graphics() {
	local NAME="$1"
	local SOKOL="$2"

	if [[ "$(uname)" == "Darwin" ]]; then
		odin build . -collection:sokol="$SOKOL" -out:"$NAME"
		local APP="/tmp/$NAME.app"
		rm -rf "$APP"
		mkdir -p "$APP/Contents/MacOS"
		cp "$NAME" "$APP/Contents/MacOS/$NAME"
		cat > "$APP/Contents/Info.plist" <<-PLIST
			<?xml version="1.0" encoding="UTF-8"?>
			<plist version="1.0"><dict>
			  <key>CFBundleExecutable</key><string>$NAME</string>
			  <key>CFBundleIdentifier</key><string>dev.learn.$NAME</string>
			  <key>CFBundleName</key><string>$NAME</string>
			  <key>CFBundlePackageType</key><string>APPL</string>
			  <key>NSHighResolutionCapable</key><true/>
			</dict></plist>
		PLIST
		open "$APP"
	else
		odin run . -collection:sokol="$SOKOL"
	fi
}
