# Allegro icon pack

## Files

- `icon.svg` — the mark only, transparent background. Use inline anywhere.
- `AppIcon.svg` — the full app icon (cream squircle tile + mark). Source of truth for the .icns.
- `AppIcon-{64,128,256,512}.png` — standalone rasters for general use (web, README, etc).
- `favicon-{32,64,192}.png` — mark-only rasters for browser tabs / web favicons.
- `AppIcon.iconset/` — the macOS .iconset folder, ready for `iconutil`.
- `build-icns.sh` — renames `-2x` → `@2x` and runs `iconutil` to produce `Allegro.icns`.

## Producing Allegro.icns

```bash
bash assets/build-icns.sh
```

This outputs `assets/Allegro.icns`. Drop it into your Xcode target's asset catalog, or set it as `CFBundleIconFile` in `Info.plist`.

## Why the `-2x` filenames?

`iconutil` expects names like `icon_16x16@2x.png`, but the project filesystem here disallows `@`. The build script renames in-place, runs `iconutil`, then renames back — so the source folder stays editable and the produced `.icns` is fully Apple-compliant.

## Colors

- Ink: `#2a2620` (warm near-black, oklch 0.18 0.012 60)
- Carmine: `#C7264F` (oklch 0.55 0.205 18)
- Tile: radial cream gradient `#fbf7ee` → `#f0e6d3` (30% 20%, r 140%)
