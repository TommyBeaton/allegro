import Foundation
import SwiftUI

enum DefaultsKey {
    static let wpm = "wpm"
    static let fontSize = "fontSize"
    static let fontFamily = "fontFamily"
    static let doubleTapWindowMs = "doubleTapWindowMs"
    static let rewindStep = "rewindStep"
    static let orpColorHex = "orpColorHex"
    static let autoPlayOnGrab = "autoPlayOnGrab"
    static let startDelayMs = "startDelayMs"
    static let pauseOnPunctuation = "pauseOnPunctuation"

    // General-tab additions
    static let showMenuBarIcon = "showMenuBarIcon"
    static let openNear = "openNear"
    static let appearance = "appearance"
}

enum DefaultsValue {
    static let wpm: Int = 300
    static let fontSize: Double = 36
    static let fontFamily: String = FontFamily.mono.rawValue
    static let doubleTapWindowMs: Int = 500
    static let rewindStep: Int = 10
    static let orpColorHex: String = "#C7264F"
    static let autoPlayOnGrab: Bool = true
    static let startDelayMs: Int = 1500
    static let pauseOnPunctuation: Bool = true

    static let showMenuBarIcon: Bool = true
    static let openNear: String = OpenNear.cursor.rawValue
    static let appearance: String = Appearance.system.rawValue
}

extension UserDefaults {
    static func registerAllegroDefaults() {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.wpm: DefaultsValue.wpm,
            DefaultsKey.fontSize: DefaultsValue.fontSize,
            DefaultsKey.fontFamily: DefaultsValue.fontFamily,
            DefaultsKey.doubleTapWindowMs: DefaultsValue.doubleTapWindowMs,
            DefaultsKey.rewindStep: DefaultsValue.rewindStep,
            DefaultsKey.orpColorHex: DefaultsValue.orpColorHex,
            DefaultsKey.autoPlayOnGrab: DefaultsValue.autoPlayOnGrab,
            DefaultsKey.startDelayMs: DefaultsValue.startDelayMs,
            DefaultsKey.pauseOnPunctuation: DefaultsValue.pauseOnPunctuation,
            DefaultsKey.showMenuBarIcon: DefaultsValue.showMenuBarIcon,
            DefaultsKey.openNear: DefaultsValue.openNear,
            DefaultsKey.appearance: DefaultsValue.appearance,
        ])
    }

    /// Wipe every Allegro key so the next read returns registered defaults.
    static func resetAllegroDefaults() {
        let keys: [String] = [
            DefaultsKey.wpm,
            DefaultsKey.fontSize,
            DefaultsKey.fontFamily,
            DefaultsKey.doubleTapWindowMs,
            DefaultsKey.rewindStep,
            DefaultsKey.orpColorHex,
            DefaultsKey.autoPlayOnGrab,
            DefaultsKey.startDelayMs,
            DefaultsKey.pauseOnPunctuation,
            DefaultsKey.showMenuBarIcon,
            DefaultsKey.openNear,
            DefaultsKey.appearance,
        ]
        for k in keys {
            UserDefaults.standard.removeObject(forKey: k)
        }
    }
}

// MARK: - Enums backed by AppStorage strings

enum FontFamily: String, CaseIterable, Identifiable {
    case mono       // JetBrains Mono (bundled)
    case sfMono     // SF Mono
    case serif      // New York
    case sans       // SF Pro

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .mono:   return "JetBrains Mono"
        case .sfMono: return "SF Mono"
        case .serif:  return "New York"
        case .sans:   return "SF Pro"
        }
    }

    /// SwiftUI `Font.Design` for system fonts. JetBrains Mono falls back to
    /// monospaced design here until a bundled font is wired up.
    var design: Font.Design {
        switch self {
        case .mono, .sfMono: return .monospaced
        case .serif:         return .serif
        case .sans:          return .default
        }
    }
}

enum OpenNear: String, CaseIterable, Identifiable {
    case cursor
    case selection
    case center
    case last

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .cursor:    return "Cursor"
        case .selection: return "Top of selection"
        case .center:    return "Screen centre"
        case .last:      return "Where I last left it"
        }
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Match system"
        case .light:  return "Always light"
        case .dark:   return "Always dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xff) / 255
        let g = Double((v >> 8) & 0xff) / 255
        let b = Double(v & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Brand carmine — used as the global tint for sliders, toggles, tabs.
    static let allegroAccent = Color(hex: DefaultsValue.orpColorHex) ?? .pink
}
