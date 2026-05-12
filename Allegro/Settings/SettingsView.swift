import SwiftUI
import AppKit
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    var body: some View {
        TabView {
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }
            TriggerTab()
                .tabItem { Label("Trigger", systemImage: "command") }
            ReadingTab()
                .tabItem { Label("Reading", systemImage: "text.alignleft") }
        }
        .tint(.allegroAccent)
        .frame(
            minWidth: 480, idealWidth: 560, maxWidth: .infinity,
            minHeight: 380, idealHeight: 480, maxHeight: .infinity
        )
    }
}

// MARK: - About

private struct AboutTab: View {
    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let b = info?["CFBundleVersion"] as? String ?? "0"
        return "Version \(v) · build \(b)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 28)

            // Lockup: mark + wordmark + tempo marking (mirrors the
            // marketing site's brand: serif "Allegro" with mono italic
            // "ma non troppo" behind a carmine pipe).
            //
            // Image("AboutAppIcon") uses a dedicated hi-res imageset
            // (256/512 PNG pair). The bundled AppIcon.icns is compiled
            // with reps only up to 256px, which looks soft at 56pt on
            // retina; the standalone imageset gives us 512px to
            // downsample from.
            HStack(spacing: 14) {
                Image("AboutAppIcon")
                    .interpolation(.high)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Allegro")
                        .font(.system(size: 32, weight: .regular, design: .serif))
                    HStack(spacing: 7) {
                        // Carmine pipe — mirrors the marketing brand. Use
                        // Color(hex:) directly so we don't depend on
                        // Color.allegroAccent being declared (it lives in
                        // Defaults.swift; if that ever moves, this still
                        // renders the brand red).
                        Rectangle()
                            .fill(Color(hex: "#C7264F") ?? .red)
                            .frame(width: 2, height: 14)
                        Text("ma non troppo")
                            .font(.system(size: 11, design: .monospaced).italic())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Version
            VStack(spacing: 4) {
                Text(versionString)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(.top, 22)
                Text("You're on the latest version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Actions
            HStack(spacing: 10) {
                Button("Check for Updates") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/TommyBeaton/allegro/releases/latest")!)
                }
                Button("Release Notes") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/TommyBeaton/allegro/releases")!)
                }
            }
            .padding(.top, 14)

            // Links
            HStack(spacing: 18) {
                Link("Website", destination: URL(string: "https://tommybeaton.github.io/allegro/")!)
                Link("Source · GitHub", destination: URL(string: "https://github.com/TommyBeaton/allegro")!)
                Link("Report an issue", destination: URL(string: "https://github.com/TommyBeaton/allegro/issues")!)
            }
            .font(.caption)
            .padding(.top, 18)

            Spacer()

            VStack(spacing: 2) {
                Text("© 2026 · Allegro is open-source under the MIT License.")
                Text("A tiny speed-reader for macOS. Made with caffeine and saccade research.")
            }
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @AppStorage(DefaultsKey.showMenuBarIcon) private var showMenuBar: Bool = DefaultsValue.showMenuBarIcon
    @AppStorage(DefaultsKey.openNear) private var openNear: String = DefaultsValue.openNear
    @AppStorage(DefaultsKey.appearance) private var appearance: String = DefaultsValue.appearance

    var body: some View {
        Form {
            Section("System") {
                LaunchAtLogin.Toggle("Launch at login")
                Toggle("Show menu-bar icon", isOn: $showMenuBar)
                    .help("Hide if you only use the hotkey.")
            }

            Section {
                Picker("Open near", selection: $openNear) {
                    ForEach(OpenNear.allCases) { o in
                        Text(o.displayName).tag(o.rawValue)
                    }
                }
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { a in
                        Text(a.displayName).tag(a.rawValue)
                    }
                }
            } header: {
                Text("Reader window")
            } footer: {
                Text("Position only — size and shape are unaffected by this setting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Trigger

private struct TriggerTab: View {
    @AppStorage(DefaultsKey.doubleTapWindowMs) private var doubleTapWindowMs: Int = DefaultsValue.doubleTapWindowMs

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Trigger key", name: .activate)
            } header: {
                Text("Hotkey")
            } footer: {
                Text("Press your chosen key twice within the window below to open Allegro on the current selection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Double-tap") {
                LabeledContent("Window") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(doubleTapWindowMs) },
                            set: { doubleTapWindowMs = Int($0) }
                        ), in: 200...800, step: 25)
                        Text("\(doubleTapWindowMs) ms")
                            .frame(width: 70, alignment: .trailing)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("While the reader is open") {
                ShortcutRow(label: "Play / pause", keys: ["Space"])
                ShortcutRow(label: "Rewind step",   keys: ["←"])
                ShortcutRow(label: "Advance step",  keys: ["→"])
                ShortcutRow(label: "Faster (+25 WPM)", keys: ["⌘", "↑"])
                ShortcutRow(label: "Slower (−25 WPM)", keys: ["⌘", "↓"])
                ShortcutRow(label: "Close", keys: ["Esc"])
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutRow: View {
    let label: String
    let keys: [String]
    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { k in
                    Text(k)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                        )
                }
            }
        }
    }
}

// MARK: - Reading

private struct ReadingTab: View {
    @AppStorage(DefaultsKey.wpm) private var wpm: Int = DefaultsValue.wpm
    @AppStorage(DefaultsKey.fontSize) private var fontSize: Double = DefaultsValue.fontSize
    @AppStorage(DefaultsKey.fontFamily) private var fontFamily: String = DefaultsValue.fontFamily
    @AppStorage(DefaultsKey.rewindStep) private var rewindStep: Int = DefaultsValue.rewindStep
    @AppStorage(DefaultsKey.orpColorHex) private var orpColorHex: String = DefaultsValue.orpColorHex
    @AppStorage(DefaultsKey.autoPlayOnGrab) private var autoPlay: Bool = DefaultsValue.autoPlayOnGrab
    @AppStorage(DefaultsKey.startDelayMs) private var startDelayMs: Int = DefaultsValue.startDelayMs
    @AppStorage(DefaultsKey.pauseOnPunctuation) private var pausePunct: Bool = DefaultsValue.pauseOnPunctuation

    private static let swatches: [String] = ["#C7264F", "#E58A2B", "#2A6FDB", "#1F8A5B", "#7A5AE0", "#F6EFE0"]

    var body: some View {
        Form {
            Section {
                Toggle("Auto-play when triggered", isOn: $autoPlay)
                LabeledContent("Start delay") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(startDelayMs) },
                            set: { startDelayMs = Int($0) }
                        ), in: 0...4000, step: 100)
                        .disabled(!autoPlay)
                        Text(startDelayMs == 0 ? "none" : String(format: "%.1f s", Double(startDelayMs) / 1000))
                            .frame(width: 70, alignment: .trailing)
                            .monospacedDigit()
                            .foregroundStyle(autoPlay ? .secondary : Color.secondary.opacity(0.5))
                    }
                }
            } header: {
                Text("Start")
            } footer: {
                Text("Delay before reading begins, so the window has time to appear before the first word.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Pace") {
                LabeledContent("Default WPM") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(wpm) },
                            set: { wpm = Int($0) }
                        ), in: 100...1000, step: 10)
                        Text("\(wpm)")
                            .frame(width: 50, alignment: .trailing)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Rewind step") {
                    Stepper(value: $rewindStep, in: 1...60) {
                        Text("\(rewindStep) words").monospacedDigit()
                    }
                }
            }

            Section("Display") {
                DisplayPreview()
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                LabeledContent("Font size") {
                    HStack {
                        Slider(value: $fontSize, in: 18...72, step: 1)
                        Text("\(Int(fontSize)) pt")
                            .frame(width: 50, alignment: .trailing)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                Picker("Font family", selection: $fontFamily) {
                    ForEach(FontFamily.allCases) { f in
                        Text(f.displayName).tag(f.rawValue)
                    }
                }
                Toggle("Pause on punctuation", isOn: $pausePunct)
                    .help("Adds a half-beat after . , ; — gives the eye a breather.")

                LabeledContent("ORP highlight") {
                    HStack(spacing: 8) {
                        ForEach(Self.swatches, id: \.self) { hex in
                            SwatchButton(hex: hex, selectedHex: $orpColorHex)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Reset to defaults", role: .destructive) {
                        UserDefaults.resetAllegroDefaults()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

/// Mini-RSVP card that mirrors Font / Font family / ORP-colour choices
/// live so users can see the effect of their changes without triggering
/// the real reader.
private struct DisplayPreview: View {
    @AppStorage(DefaultsKey.fontSize) private var fontSize: Double = DefaultsValue.fontSize
    @AppStorage(DefaultsKey.fontFamily) private var fontFamilyRaw: String = DefaultsValue.fontFamily
    @AppStorage(DefaultsKey.orpColorHex) private var orpColorHex: String = DefaultsValue.orpColorHex

    // "Allegro" → 7-char ORP bucket is index 2 → second "l".
    private let word = "Allegro"
    private let orpIndex = 2

    private var family: FontFamily { FontFamily(rawValue: fontFamilyRaw) ?? .mono }
    private var orpColor: Color { Color(hex: orpColorHex) ?? .pink }

    /// Cap the preview size so a 72pt Font setting doesn't overflow the
    /// Settings form. Real reader honours the full slider value.
    private var renderedSize: CGFloat { min(CGFloat(fontSize), 44) }
    private var font: Font { .system(size: renderedSize, weight: .medium, design: family.design) }

    var body: some View {
        let chars = Array(word)
        let before = chars.prefix(orpIndex).map(String.init).joined()
        let pivot = String(chars[orpIndex])
        let after = chars.suffix(from: orpIndex + 1).map(String.init).joined()

        VStack(spacing: 6) {
            ZStack {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 1)
                HStack(spacing: 0) {
                    Text(before).font(font).foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(pivot).font(font).foregroundStyle(orpColor)
                    Text(after).font(font).foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: renderedSize * 1.8)

            Text("PREVIEW")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.04))
        )
        .padding(.vertical, 6)
        // Live updates as user moves the sliders / picks colours.
        .animation(.easeInOut(duration: 0.12), value: fontSize)
        .animation(.easeInOut(duration: 0.12), value: orpColorHex)
        .animation(.easeInOut(duration: 0.12), value: fontFamilyRaw)
    }
}

private struct SwatchButton: View {
    let hex: String
    @Binding var selectedHex: String

    var body: some View {
        let isSelected = selectedHex.uppercased() == hex.uppercased()
        Button {
            selectedHex = hex
        } label: {
            Circle()
                .fill(Color(hex: hex) ?? .pink)
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(isSelected ? 0.85 : 0.0), lineWidth: 2)
                        .padding(-3)
                )
                .overlay(
                    Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(hex)
    }
}
