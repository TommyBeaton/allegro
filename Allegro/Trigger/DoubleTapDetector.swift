import Foundation

/// Buffers single key events and emits exactly once when two presses
/// arrive within `windowSeconds`. State resets on every fire so a third
/// rapid press starts a new pair rather than re-firing.
final class DoubleTapDetector {
    private var lastPress: Date?
    private let now: () -> Date

    /// Closure used to read the window each press — so settings changes
    /// take effect immediately without re-instantiating.
    private let windowProvider: () -> TimeInterval

    init(
        windowProvider: @escaping () -> TimeInterval,
        now: @escaping () -> Date = Date.init
    ) {
        self.windowProvider = windowProvider
        self.now = now
    }

    /// Returns true when this press completes a double-tap.
    @discardableResult
    func register() -> Bool {
        let t = now()
        if let prev = lastPress, t.timeIntervalSince(prev) <= windowProvider() {
            lastPress = nil
            return true
        }
        lastPress = t
        return false
    }
}
