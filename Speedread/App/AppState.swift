import AppKit
import SwiftUI

/// Composition root. Owns the engine, hotkey monitor, and panel.
@MainActor
final class AppState: ObservableObject {
    let engine: ReaderEngine
    private var hotkey: HotkeyMonitor?
    private var panel: ReaderPanel?

    init() {
        UserDefaults.registerSpeedreadDefaults()
        self.engine = ReaderEngine()
    }

    func start() {
        let detector = DoubleTapDetector(windowProvider: {
            let ms = UserDefaults.standard.integer(forKey: DefaultsKey.doubleTapWindowMs)
            let safe = ms > 0 ? ms : DefaultsValue.doubleTapWindowMs
            return TimeInterval(safe) / 1000
        })
        hotkey = HotkeyMonitor(detector: detector) { [weak self] in
            self?.handleTrigger()
        }
        hotkey?.start()
    }

    func handleTrigger() {
        Task { @MainActor in
            do {
                let text = try await SelectionGrabber.grab()
                engine.load(text, autoPlay: true)
                showPanel()
            } catch SelectionGrabber.GrabError.accessibilityNotTrusted {
                presentAccessibilityAlert()
            } catch {
                NSSound.beep()
            }
        }
    }

    /// Open the panel manually with whatever's on the clipboard — used by the menu-bar action.
    func openFromClipboard() {
        if let s = NSPasteboard.general.string(forType: .string),
           !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            engine.load(s, autoPlay: true)
            showPanel()
        } else {
            NSSound.beep()
        }
    }

    private func showPanel() {
        if panel == nil {
            let engine = self.engine
            let view = ReaderRootView(engine: engine) { [weak self] in
                self?.panel?.orderOut(nil)
            }
            panel = ReaderPanel(rootView: view)
        }
        panel?.showNearMouse()
    }

    private func presentAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility permission required"
        alert.informativeText = "Speedread needs Accessibility access to read the text you have selected. Open System Settings → Privacy & Security → Accessibility and enable Speedread, then try again."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
