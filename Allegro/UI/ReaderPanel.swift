import AppKit
import SwiftUI

/// Floating, non-activating panel that hosts the SwiftUI reader UI.
final class ReaderPanel: NSPanel {
    init(rootView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 220),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        isReleasedWhenClosed = false
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        setFrameAutosaveName("AllegroPanel")

        let host = NSHostingView(rootView: AnyView(rootView))
        host.autoresizingMask = [.width, .height]
        contentView = host
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Position the panel near the current mouse, clamped to the active screen.
    func showNearMouse() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let screen else {
            makeKeyAndOrderFront(nil)
            return
        }
        let visible = screen.visibleFrame
        var origin = NSPoint(x: mouse.x - frame.width / 2, y: mouse.y - frame.height - 20)
        origin.x = max(visible.minX + 8, min(origin.x, visible.maxX - frame.width - 8))
        origin.y = max(visible.minY + 8, min(origin.y, visible.maxY - frame.height - 8))
        setFrameOrigin(origin)
        orderFrontRegardless()
        makeKey()
    }
}
