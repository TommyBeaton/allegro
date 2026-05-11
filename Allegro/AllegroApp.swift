import SwiftUI

@main
struct AllegroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
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

            Button("Quit Allegro…") {
                delegate.state.confirmQuit()
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            // Menu-bar icons are 18pt by convention. The SVG viewBox in the
            // imageset is cropped tight to the mark, so without an explicit
            // frame it would render at its full viewBox size (~56×68pt).
            Image("AllegroMenuBarIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
