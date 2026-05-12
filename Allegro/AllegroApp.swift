import SwiftUI

@main
struct AllegroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @AppStorage(DefaultsKey.showMenuBarIcon) private var showMenuBar: Bool = DefaultsValue.showMenuBarIcon
    @AppStorage(DefaultsKey.appearance) private var appearanceRaw: String = DefaultsValue.appearance

    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBar) {
            MenuBarContent(state: delegate.state)
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
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}

/// Menu-bar dropdown contents.
///
/// Lives in its own View so the `@Environment(\.openSettings)` action is
/// available — that's the SwiftUI-supported way to open the Settings scene
/// for menu-bar (LSUIElement) apps. The legacy `showSettingsWindow:`
/// selector returns true from sendAction but doesn't actually create the
/// window when the app starts as `.accessory`.
private struct MenuBarContent: View {
    let state: AppState
    @Environment(\.openSettings) private var openSettingsAction

    var body: some View {
        Button("Read from Clipboard") {
            state.openFromClipboard()
        }
        .keyboardShortcut("v", modifiers: [.command, .shift])

        Divider()

        Button("Settings…") {
            state.prepareSettingsWindow()
            openSettingsAction()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Allegro…") {
            state.confirmQuit()
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
