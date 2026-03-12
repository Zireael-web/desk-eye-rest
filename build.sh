#!/usr/bin/env zsh
#
# DeskEyeRest manual build script
#
# Compiles every .swift under DeskEyeRest/ into a single binary with `swiftc`,
# embeds Info.plist into the __TEXT segment so the macOS 26 TCC infrastructure
# can find usage-description keys without the App Store / Xcode codesign chain,
# ad-hoc-signs the bundle, and copies the result into /Applications/.
#
# Uses only Command Line Tools (no Xcode required). Targets macOS 14.0+.

set -euo pipefail

PROJ_ROOT=${0:A:h}
SRC="$PROJ_ROOT/DeskEyeRest"
APP="$PROJ_ROOT/build/DeskEyeRest.app"
INFO="$SRC/Info.plist"
BIN="$APP/Contents/MacOS/DeskEyeRest"
INSTALL="/Applications/DeskEyeRest.app"

echo "→ collecting sources"
SWIFT_FILES=("${(@f)$(find "$SRC" -name "*.swift" -type f)}")
echo "  $#SWIFT_FILES Swift files"

# If app is running, quit it first so we can replace the binary.
if pgrep -f "$INSTALL/Contents/MacOS/DeskEyeRest" >/dev/null; then
  echo "→ stopping running DeskEyeRest"
  pkill -f "$INSTALL/Contents/MacOS/DeskEyeRest" || true
  # Wait briefly for clean shutdown
  for i in {1..20}; do
    pgrep -f "$INSTALL/Contents/MacOS/DeskEyeRest" >/dev/null || break
    sleep 0.1
  done
fi

echo "→ compiling"
xcrun swiftc \
  -target arm64-apple-macosx14.0 \
  -O \
  -parse-as-library \
  -framework AppKit \
  -framework SwiftUI \
  -framework Carbon \
  -framework AVFoundation \
  -framework AVFAudio \
  -framework CoreAudio \
  -framework UserNotifications \
  -framework ServiceManagement \
  -framework Intents \
  -framework Combine \
  -framework CoreText \
  -framework CoreGraphics \
  -Xlinker -sectcreate \
  -Xlinker __TEXT \
  -Xlinker __info_plist \
  -Xlinker "$INFO" \
  -o "$BIN" \
  "${SWIFT_FILES[@]}"

echo "→ syncing resources into bundle"
RES_SRC="$SRC/Resources"
RES_DST="$APP/Contents/Resources"
mkdir -p "$RES_DST"
# Copy loose top-level resources (PNGs, ICNS, etc.) – everything that
# isn't the asset catalog or the fonts folder (fonts handled below).
for f in "$RES_SRC"/*.{png,icns,plist}(N); do
  cp "$f" "$RES_DST/"
done
# Fonts folder: mirror entire directory.
rm -rf "$RES_DST/Fonts" && cp -R "$RES_SRC/Fonts" "$RES_DST/Fonts"

echo "→ codesigning (ad-hoc)"
codesign --sign - --force --deep --options runtime "$APP" 2>&1 | tail -5

echo "→ installing to /Applications/"
rm -rf "$INSTALL"
cp -R "$APP" "$INSTALL"

echo "→ done"
ls -lh "$INSTALL/Contents/MacOS/DeskEyeRest"
