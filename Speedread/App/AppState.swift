import AppKit
import SwiftUI

/// Composition root. Owns the engine, hotkey monitor, and panel.
@MainActor
final class AppState: ObservableObject {
    let engine: ReaderEngine
    private var hotkey: HotkeyMonitor?
    private var panel: ReaderPanel?
    private var startTask: Task<Void, Never>?

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
                presentText(text)
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
            presentText(s)
        } else {
            NSSound.beep()
        }
    }

    /// Open the Settings window. Works around the LSUIElement responder-chain
    /// gap by raising activation policy before sending the action and reverting
    /// when the window closes.
    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        // Find the settings window and watch for it to close.
        if let settingsWindow = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("Settings") == true || $0.title == "Settings" }) {
            settingsWindow.makeKeyAndOrderFront(nil)
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: settingsWindow,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }

    private func presentText(_ text: String) {
        startTask?.cancel()
        engine.load(text, autoPlay: false)
        showPanel()

        let auto = UserDefaults.standard.bool(forKey: DefaultsKey.autoPlayOnGrab)
        guard auto else { return }
        let delayMs = max(0, UserDefaults.standard.integer(forKey: DefaultsKey.startDelayMs))
        if delayMs == 0 {
            engine.play()
            return
        }
        startTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            guard let self, !Task.isCancelled else { return }
            // Only auto-play if the user hasn't already touched the controls.
            if self.engine.state == .paused {
                self.engine.play()
            }
        }
    }

    private func showPanel() {
        if panel == nil {
            let engine = self.engine
            let view = ReaderRootView(engine: engine) { [weak self] in
                self?.startTask?.cancel()
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
