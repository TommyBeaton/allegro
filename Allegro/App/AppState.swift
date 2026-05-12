import AppKit
import SwiftUI
import OSLog

private let settingsLog = Logger(subsystem: "app.allegro.Allegro", category: "settings")

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
            } catch SelectionGrabber.GrabError.timeout {
                // The synth-⌘C never made the pasteboard tick. Two
                // possibilities: the user didn't actually have text
                // selected, or macOS quietly revoked Accessibility
                // (granting in Settings doesn't always re-propagate to
                // a running process). Distinguish them.
                if !SelectionGrabber.isTrustedSilently() {
                    presentAccessibilityRevokedAlert()
                } else {
                    NSSound.beep()
                }
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
    /// Called immediately before SwiftUI's `openSettings` action fires.
    /// Raises the activation policy to `.regular` so the Settings window
    /// is allowed to become key (an LSUIElement / `.accessory` app can
    /// show a settings window but it won't focus), then schedules a
    /// short retry loop that finds the new window, brings it forward,
    /// and arranges to revert the policy when the user closes it.
    func prepareSettingsWindow() {
        settingsLog.info("prepareSettingsWindow called, activationPolicy=\(NSApp.activationPolicy().rawValue, privacy: .public)")
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        Task { @MainActor in
            for i in 0..<10 {
                if let win = NSApp.windows.first(where: Self.isSettingsWindow) {
                    settingsLog.info("retry \(i, privacy: .public): found Settings window")
                    win.makeKeyAndOrderFront(nil)
                    self.observeSettingsClose(win)
                    return
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            settingsLog.error("gave up looking for Settings window after 500ms")
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private static func isSettingsWindow(_ w: NSWindow) -> Bool {
        if let id = w.identifier?.rawValue,
           id.contains("Settings") || id.contains("preferences") || id == "com_apple_SwiftUI_Settings_window" {
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
            if self.engine.state == .paused {
                self.engine.play()
            }
        }
    }

    private func showPanel() {
        if panel == nil {
            let engine = self.engine
            let newPanel = ReaderPanel(rootView: ReaderRootView(engine: engine) { [weak self] in
                // Esc / programmatic close path. The system close button
                // routes through willCloseNotification below instead.
                self?.panel?.performClose(nil)
            })
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: newPanel,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.startTask?.cancel()
                    self?.engine.pause()
                }
            }
            panel = newPanel
        }
        let raw = UserDefaults.standard.string(forKey: DefaultsKey.openNear) ?? DefaultsValue.openNear
        let where_ = OpenNear(rawValue: raw) ?? .cursor
        panel?.show(at: where_)
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

    private func presentAccessibilityRevokedAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility permission was revoked"
        alert.informativeText = "macOS no longer trusts Allegro to read your text selection. This usually happens after the app was updated — Accessibility needs to be re-enabled and the app relaunched."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
