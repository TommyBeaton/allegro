#!/usr/bin/env bash
# Build Allegro.icns from AppIcon.iconset.
#
# Filenames here use "-2x" instead of "@2x" because the build environment
# disallowed "@" in paths. This script renames them to the Apple-standard
# form, runs iconutil, then restores the safe names.
#
# Run from the project root:
#   bash assets/build-icns.sh
#
# Output: assets/Allegro.icns

set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SET="$HERE/AppIcon.iconset"

cd "$SET"
for f in *-2x.png; do
  mv "$f" "${f/-2x/@2x}"
done

cd "$HERE"
iconutil -c icns AppIcon.iconset -o Allegro.icns

# restore safe names so the source folder stays editable here
cd "$SET"
for f in *@2x.png; do
  mv "$f" "${f/@2x/-2x}"
done

echo "✓ wrote $HERE/Allegro.icns"
