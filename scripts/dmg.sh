#!/usr/bin/env bash
# Build a Release .app and wrap it in a .dmg.
#
# Unsigned by default (works for personal / GitHub-release sharing, but
# users will see a Gatekeeper warning). To produce a signed + notarised
# DMG suitable for public distribution, set:
#
#   DEV_ID="Developer ID Application: Your Name (TEAMID)"
#   NOTARY_PROFILE="speedread-notary"   # stored via `xcrun notarytool store-credentials`
#
# Both require a paid Apple Developer Program account.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Speedread/Info.plist 2>/dev/null || echo "0.1.0")
BUILD_DIR="build"
APP="$BUILD_DIR/Build/Products/Release/Speedread.app"
STAGE="$BUILD_DIR/dmg-stage"
DMG="$BUILD_DIR/Speedread-$VERSION.dmg"

echo "→ Regenerating Xcode project"
xcodegen generate >/dev/null

echo "→ Building Release"
xcodebuild \
    -project Speedread.xcodeproj \
    -scheme Speedread \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -quiet \
    build

if [[ ! -d "$APP" ]]; then
    echo "Build succeeded but $APP not found." >&2
    exit 1
fi

if [[ -n "${DEV_ID:-}" ]]; then
    echo "→ Codesigning with $DEV_ID"
    codesign --deep --force --options runtime \
        --sign "$DEV_ID" \
        --timestamp \
        "$APP"
    codesign --verify --deep --strict --verbose=2 "$APP"
else
    echo "  (skipping codesign — set DEV_ID to enable)"
fi

echo "→ Staging DMG contents"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "→ Building $DMG"
rm -f "$DMG"
hdiutil create \
    -volname "Speedread $VERSION" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG" >/dev/null

if [[ -n "${DEV_ID:-}" ]]; then
    echo "→ Codesigning DMG"
    codesign --force --sign "$DEV_ID" --timestamp "$DMG"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "→ Notarising (this can take a few minutes)"
    xcrun notarytool submit "$DMG" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    echo "→ Stapling notarization ticket"
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
else
    echo "  (skipping notarisation — set NOTARY_PROFILE to enable)"
fi

echo
echo "✓ $DMG"
ls -lh "$DMG"
