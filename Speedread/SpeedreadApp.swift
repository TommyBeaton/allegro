import SwiftUI

@main
struct SpeedreadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Speedread", systemImage: "text.viewfinder") {
            Button("Read from Clipboard") {
                delegate.state.openFromClipboard()
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])

            Divider()

            Button("Settings…") {
                delegate.state.openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Speedread") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
