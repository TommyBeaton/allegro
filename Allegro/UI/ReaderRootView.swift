import SwiftUI

struct ReaderRootView: View {
    @ObservedObject var engine: ReaderEngine
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle / close
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            RSVPView(engine: engine)
                .padding(.horizontal, 24)

            ControlsView(engine: engine)
        }
        .background(.thinMaterial)
        .onAppear {
            // Ensure keyboard shortcuts within the panel respond.
        }
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .left: engine.step(by: -1)
            case .right: engine.step(by: 1)
            default: break
            }
        }
    }
}
