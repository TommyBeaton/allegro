import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state: AppState

    override init() {
        self.state = AppState()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        state.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Menu-bar app; do nothing on dock-click (there is no dock icon).
        return true
    }
}
