import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }
            TriggerTab()
                .tabItem { Label("Trigger", systemImage: "command") }
            ReadingTab()
                .tabItem { Label("Reading", systemImage: "text.alignleft") }
        }
        .frame(
            minWidth: 480, idealWidth: 560, maxWidth: .infinity,
            minHeight: 360, idealHeight: 460, maxHeight: .infinity
        )
    }
}

private struct GeneralTab: View {
    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle("Launch at login")
            }
        }
        .formStyle(.grouped)
    }
}

private struct TriggerTab: View {
    @AppStorage(DefaultsKey.doubleTapWindowMs) private var doubleTapWindowMs: Int = DefaultsValue.doubleTapWindowMs

    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Trigger key", name: .activate)
                Text("Press your chosen key twice within the window below to open Speedread on the current selection.")
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
        }
        .formStyle(.grouped)
    }
}

private struct ReadingTab: View {
    @AppStorage(DefaultsKey.wpm) private var wpm: Int = DefaultsValue.wpm
    @AppStorage(DefaultsKey.fontSize) private var fontSize: Double = DefaultsValue.fontSize
    @AppStorage(DefaultsKey.rewindStep) private var rewindStep: Int = DefaultsValue.rewindStep
    @AppStorage(DefaultsKey.orpColorHex) private var orpColorHex: String = DefaultsValue.orpColorHex
    @AppStorage(DefaultsKey.autoPlayOnGrab) private var autoPlay: Bool = DefaultsValue.autoPlayOnGrab
    @AppStorage(DefaultsKey.startDelayMs) private var startDelayMs: Int = DefaultsValue.startDelayMs

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
                        Text("\(rewindStep) words")
                            .monospacedDigit()
                    }
                }
            }

            Section("Display") {
                LabeledContent("Font size") {
                    HStack {
                        Slider(value: $fontSize, in: 18...72, step: 1)
                        Text("\(Int(fontSize)) pt")
                            .frame(width: 50, alignment: .trailing)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                ColorPicker("ORP highlight", selection: Binding(
                    get: { Color(hex: orpColorHex) ?? .pink },
                    set: { newColor in
                        if let hex = newColor.toHex() { orpColorHex = hex }
                    }
                ))
            }
        }
        .formStyle(.grouped)
    }
}

private extension Color {
    func toHex() -> String? {
        #if canImport(AppKit)
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return nil
        #endif
    }
}
