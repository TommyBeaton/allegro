import SwiftUI

struct ReaderRootView: View {
    @ObservedObject var engine: ReaderEngine
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // The system close button (red traffic light) lives in the
            // window titlebar at top-left. fullSizeContentView lets our
            // content slide behind it; we reserve ~26pt so RSVPView never
            // overlaps the button.
            Color.clear.frame(height: 26)

            RSVPView(engine: engine)
                .padding(.horizontal, 24)

            ControlsView(engine: engine)
        }
        .background(.thinMaterial)
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .left:  engine.step(by: -1)
            case .right: engine.step(by: 1)
            default:     break
            }
        }
        // Hidden buttons carry the keyboard shortcuts the Trigger tab
        // documents. They have no visible UI but participate in the
        // responder chain.
        .background(
            Group {
                Button("") { engine.setWPM(engine.wpm + 25) }
                    .keyboardShortcut(.upArrow, modifiers: .command)
                Button("") { engine.setWPM(engine.wpm - 25) }
                    .keyboardShortcut(.downArrow, modifiers: .command)
                Button("") { onClose() }
                    .keyboardShortcut(.cancelAction) // Esc
            }
            .opacity(0)
            .accessibilityHidden(true)
        )
    }
}
