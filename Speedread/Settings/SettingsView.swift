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
        .frame(width: 460)
        .padding(20)
    }
}

private struct GeneralTab: View {
    var body: some View {
        Form {
            LaunchAtLogin.Toggle("Launch at login")
        }
    }
}

private struct TriggerTab: View {
    @AppStorage(DefaultsKey.doubleTapWindowMs) private var doubleTapWindowMs: Int = DefaultsValue.doubleTapWindowMs

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Trigger key", name: .activate)
                Text("Press your chosen key **twice** within the window below to open Speedread on the current selection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    Text("Double-tap window")
                    Slider(value: Binding(
                        get: { Double(doubleTapWindowMs) },
                        set: { doubleTapWindowMs = Int($0) }
                    ), in: 200...800, step: 25)
                    Text("\(doubleTapWindowMs) ms")
                        .frame(width: 70, alignment: .trailing)
                        .monospacedDigit()
                }
            }
        }
    }
}

private struct ReadingTab: View {
    @AppStorage(DefaultsKey.wpm) private var wpm: Int = DefaultsValue.wpm
    @AppStorage(DefaultsKey.fontSize) private var fontSize: Double = DefaultsValue.fontSize
    @AppStorage(DefaultsKey.rewindStep) private var rewindStep: Int = DefaultsValue.rewindStep
    @AppStorage(DefaultsKey.orpColorHex) private var orpColorHex: String = DefaultsValue.orpColorHex

    var body: some View {
        Form {
            Section("Pace") {
                HStack {
                    Text("Default WPM")
                    Slider(value: Binding(
                        get: { Double(wpm) },
                        set: { wpm = Int($0) }
                    ), in: 100...1000, step: 10)
                    Text("\(wpm)").frame(width: 50, alignment: .trailing).monospacedDigit()
                }
                HStack {
                    Text("Rewind step")
                    Stepper(value: $rewindStep, in: 1...60) { Text("\(rewindStep) words") }
                }
            }
            Section("Display") {
                HStack {
                    Text("Font size")
                    Slider(value: $fontSize, in: 18...72, step: 1)
                    Text("\(Int(fontSize)) pt").frame(width: 50, alignment: .trailing).monospacedDigit()
                }
                ColorPicker("ORP highlight", selection: Binding(
                    get: { Color(hex: orpColorHex) ?? .pink },
                    set: { newColor in
                        if let hex = newColor.toHex() { orpColorHex = hex }
                    }
                ))
            }
        }
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
