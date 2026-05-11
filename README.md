# Speedread

A DeepL-style floating popup for macOS that speed-reads whatever text is currently selected.

Trigger: press a configurable hotkey **twice** in quick succession (default `⌘⇧R`, `⌘⇧R`). The selection is grabbed and shown one word at a time using RSVP (rapid serial visual presentation) with the ORP character highlighted, à la Spritz / Spreader / Outread.

> **v1 status:** RSVP mode only. Bionic / Jiffy and chunked modes are queued for v2.

## Build

You need a Mac with Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
xcodegen generate
open Speedread.xcodeproj
```

Build & run the `Speedread` scheme. On first run, macOS will ask for Accessibility permission (System Settings → Privacy & Security → Accessibility) — Speedread needs this to synthesise `⌘C` and read your selection.

## Usage

1. Select text anywhere on macOS (browser, PDF, mail, …).
2. Press the trigger twice quickly (default `⌘⇧R` ⇒ `⌘⇧R`).
3. The floating panel appears near the cursor and starts reading.

In-panel controls:

| Key | Action |
|---|---|
| `Space` | Play / pause |
| `←` / `→` | Step ±1 word |
| `⇧←` / `⇧→` | Step ±10 words |
| `Esc` | Hide panel |

Controls bar: play/pause, rewind 10, WPM slider, scrub bar, close.

## Settings

Open via the menu-bar icon → Settings (or `⌘,` while the panel is focused).

- **General** — launch at login.
- **Trigger** — rebind the hotkey (any combo, just not `⌘C` so it doesn't clash with DeepL), adjust the double-tap window (200–800 ms).
- **Reading** — default WPM, font size, ORP highlight colour, rewind step.

## Project layout

See `Speedread/` — file-by-file purpose is described in the approved plan under `~/.claude/plans/`.
