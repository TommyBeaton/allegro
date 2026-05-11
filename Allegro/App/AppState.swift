import AppKit
import SwiftUI

/// Composition root. Owns the engine, hotkey monitor, and panel.
@MainActor
final class AppState: ObservableObject {
    let engine: ReaderEngine
    private var hotkey: HotkeyMonitor?
    private var panel: ReaderPanel?
    private var startTask: Task<Void, Never>?
    private var settingsCloseObserver: NSObjectProtocol?

    init() {
        UserDefaults.registerAllegroDefaults()
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
    /// gap: raises activation policy, sends the show-settings action, then
    /// retries finding the window for a short window (it may not exist
    /// synchronously after the action returns).
    func openSettings() {
        NSApp.setActivationPolicy(.regular)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }

        // The settings window is created asynchronously. Retry a handful of
        // times over ~300 ms so the first-ever click is as reliable as a
        // re-open.
        Task { @MainActor in
            for _ in 0..<6 {
                if let win = NSApp.windows.first(where: Self.isSettingsWindow) {
                    NSApp.activate(ignoringOtherApps: true)
                    win.makeKeyAndOrderFront(nil)
                    self.observeSettingsClose(win)
                    return
                }
                try? await Task.sleep(nanoseconds: 50_000_000) // 50 ms
            }
            // Window never showed; revert policy so we don't leave a stray Dock icon.
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private static func isSettingsWindow(_ w: NSWindow) -> Bool {
        if let id = w.identifier?.rawValue, id.contains("Settings") || id.contains("preferences") {
            return true
        }
        return w.title == "Settings" || w.title.contains("Settings")
    }

    private func observeSettingsClose(_ window: NSWindow) {
        if let prev = settingsCloseObserver {
            NotificationCenter.default.removeObserver(prev)
        }
        settingsCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            Task { @MainActor in
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    /// Confirm before terminating — accidentally hitting Quit kills the
    /// global hotkey, which is the whole point of the app. Users typically
    /// don't realise menu-bar apps can just be left running.
    func confirmQuit() {
        let alert = NSAlert()
        alert.messageText = "Quit Allegro?"
        alert.informativeText = "Your speed-read hotkey will stop working until you launch Allegro again. Allegro uses almost no CPU when idle — you can leave it in the menu bar."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Keep Running")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
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
        alert.informativeText = "Allegro needs Accessibility access to read the text you have selected. Open System Settings → Privacy & Security → Accessibility and enable Allegro, then try again."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
