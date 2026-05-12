import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Single shortcut that the user double-taps to trigger Allegro.
    /// Default chosen to avoid clashing with DeepL's Cmd+C+C.
    static let activate = Self("activate", default: .init(.r, modifiers: [.command, .shift]))
}

/// Wires `KeyboardShortcuts.onKeyDown(.activate)` into a `DoubleTapDetector`
/// and calls `onTrigger` once per detected double-tap.
@MainActor
final class HotkeyMonitor {
    private let detector: DoubleTapDetector
    private let onTrigger: () -> Void

    init(detector: DoubleTapDetector, onTrigger: @escaping () -> Void) {
        self.detector = detector
        self.onTrigger = onTrigger
    }

    func start() {
        KeyboardShortcuts.onKeyDown(for: .activate) { [weak self] in
            guard let self else { return }
            if self.detector.register() {
                self.onTrigger()
            }
        }
    }
}
