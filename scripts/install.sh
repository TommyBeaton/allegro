#!/usr/bin/env bash
# Build Allegro in Release config and install it to /Applications.
set -euo pipefail

cd "$(dirname "$0")/.."

DEST="/Applications/Allegro.app"
BUILD_DIR="build"

echo "→ Regenerating Xcode project"
xcodegen generate >/dev/null

echo "→ Building Release"
xcodebuild \
    -project Allegro.xcodeproj \
    -scheme Allegro \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -quiet \
    build

APP="$BUILD_DIR/Build/Products/Release/Allegro.app"
if [[ ! -d "$APP" ]]; then
    echo "Build succeeded but $APP not found." >&2
    exit 1
fi

echo "→ Installing to $DEST"
if [[ -d "$DEST" ]]; then
    # If the previous install is running, terminate it so cp can replace it.
    pkill -x Allegro 2>/dev/null || true
    rm -rf "$DEST"
fi
cp -R "$APP" "$DEST"

# Clear the quarantine flag so Gatekeeper doesn't complain about an
# unsigned local build on first launch.
find "$DEST" -print0 | xargs -0 xattr -d com.apple.quarantine 2>/dev/null || true

echo "→ Launching"
open "$DEST"

echo "✓ Installed Allegro to $DEST"
echo "  (search for 'Allegro' in Spotlight, or pin it from /Applications)"
