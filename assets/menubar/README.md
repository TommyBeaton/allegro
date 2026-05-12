# Allegro menu-bar icon — Xcode wire-up

## What this is

`AllegroMenuBarIcon.imageset/` is a ready-to-drop Xcode imageset containing a single template SVG of the Allegro mark (trapezoid with the diagonal pendulum slot cut out). It's marked as a **template image**, so macOS automatically tints it black or white to match the menu-bar appearance — no light/dark variants needed.

## Install (30 seconds)

1. In Xcode, open `Allegro/Assets.xcassets`.
2. Drag the **`AllegroMenuBarIcon.imageset`** folder from here directly into the asset catalog sidebar.
3. Open `AllegroApp.swift` and change:

```swift
// before
MenuBarExtra("Allegro", systemImage: "metronome") {

// after
MenuBarExtra("Allegro", image: "AllegroMenuBarIcon") {
```

That's the whole change. Build & run — the SF Symbol metronome is replaced with the Allegro mark, correctly inverted on dark menu bars.

## Why a template image and not the full app icon?

macOS menu-bar icons are flat silhouettes by Apple convention — they sit alongside system icons (Wi-Fi, battery, Spotlight) which are all monochrome and template-tinted. A coloured icon there reads as foreign.

The carmine pendulum slot becomes a cut-out (negative space) using `fill-rule="evenodd"`. You still recognise the metronome, and it stays legible at 18pt.

## Files

- `AllegroMenuBarIcon.imageset/AllegroMenuBarIcon.svg` — the source. ViewBox is cropped tight around the mark with ~10% pad so it fills the menu bar slot well.
- `AllegroMenuBarIcon.imageset/Contents.json` — Xcode metadata. `preserves-vector-representation: true` keeps it sharp at every scale; `template-rendering-intent: template` makes macOS tint it.
