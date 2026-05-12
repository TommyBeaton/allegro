import AppKit
import SwiftUI

/// Floating, non-activating panel that hosts the SwiftUI reader UI.
final class ReaderPanel: NSPanel {
    init(rootView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 170),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        contentMinSize = NSSize(width: 360, height: 150)
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        isReleasedWhenClosed = false
        // Show the system close button (red traffic light) — that's the
        // Mac-native way to dismiss a window. Minimise / zoom stay hidden
        // because the reader is a fixed-purpose floating panel.
        standardWindowButton(.closeButton)?.isHidden = false
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        // Autosave name is versioned: bumping suffix invalidates any
        // stale frame restored from an older build (otherwise users keep
        // seeing the previous, taller default geometry).
        setFrameAutosaveName("AllegroPanelV2")

        let host = NSHostingView(rootView: AnyView(rootView))
        host.autoresizingMask = [.width, .height]
        contentView = host
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Position the panel according to the user's openNear preference.
    func show(at strategy: OpenNear) {
        let screen = activeScreen()
        let visible = screen?.visibleFrame ?? .zero

        var origin: NSPoint
        switch strategy {
        case .cursor, .selection:
            // Selection-top is best-effort: AX has no reliable bounding rect across
            // all apps, so we fall back to cursor for now.
            let mouse = NSEvent.mouseLocation
            origin = NSPoint(x: mouse.x - frame.width / 2,
                             y: mouse.y - frame.height - 20)
        case .center:
            origin = NSPoint(x: visible.midX - frame.width / 2,
                             y: visible.midY - frame.height / 2)
        case .last:
            // The setFrameAutosaveName above already restores last position; just show.
            orderFrontRegardless()
            makeKey()
            return
        }

        if !visible.isEmpty {
            origin.x = max(visible.minX + 8, min(origin.x, visible.maxX - frame.width - 8))
            origin.y = max(visible.minY + 8, min(origin.y, visible.maxY - frame.height - 8))
        }
        setFrameOrigin(origin)
        orderFrontRegardless()
        makeKey()
    }

    private func activeScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }
}
