import Foundation
import SwiftUI

enum DefaultsKey {
    static let wpm = "wpm"
    static let fontSize = "fontSize"
    static let doubleTapWindowMs = "doubleTapWindowMs"
    static let rewindStep = "rewindStep"
    static let orpColorHex = "orpColorHex"
}

enum DefaultsValue {
    static let wpm: Int = 300
    static let fontSize: Double = 36
    static let doubleTapWindowMs: Int = 500
    static let rewindStep: Int = 10
    static let orpColorHex: String = "#D6336C"
}

extension UserDefaults {
    static func registerSpeedreadDefaults() {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.wpm: DefaultsValue.wpm,
            DefaultsKey.fontSize: DefaultsValue.fontSize,
            DefaultsKey.doubleTapWindowMs: DefaultsValue.doubleTapWindowMs,
            DefaultsKey.rewindStep: DefaultsValue.rewindStep,
            DefaultsKey.orpColorHex: DefaultsValue.orpColorHex,
        ])
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
}
