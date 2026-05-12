import SwiftUI

struct ControlsView: View {
    @ObservedObject var engine: ReaderEngine
    @AppStorage(DefaultsKey.rewindStep) private var rewindStep: Int = DefaultsValue.rewindStep

    private static let validStepSymbols: Set<Int> = [5, 10, 15, 30, 45, 60, 75, 90]

    private var rewindIcon: String {
        Self.validStepSymbols.contains(rewindStep) ? "gobackward.\(rewindStep)" : "gobackward"
    }

    private var forwardIcon: String {
        Self.validStepSymbols.contains(rewindStep) ? "goforward.\(rewindStep)" : "goforward"
    }

    var body: some View {
        VStack(spacing: 8) {
            scrubBar
                .tint(.allegroAccent)

            HStack(spacing: 12) {
                Button {
                    engine.step(by: -rewindStep)
                } label: {
                    Image(systemName: rewindIcon)
                }
                .buttonStyle(.borderless)
                .help("Rewind \(rewindStep) words")

                Button {
                    engine.togglePlayPause()
                } label: {
                    Image(systemName: engine.state == .playing ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(Color.allegroAccent)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.space, modifiers: [])

                Button {
                    engine.step(by: rewindStep)
                } label: {
                    Image(systemName: forwardIcon)
                }
                .buttonStyle(.borderless)
                .help("Forward \(rewindStep) words")

                Divider().frame(height: 16)

                // Horizontal small-caps WPM label reads as a single unit
                // and saves the vertical space the stacked W/P/M used.
                Text("WPM")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: { Double(engine.wpm) },
                        set: { engine.setWPM(Int($0)) }
                    ),
                    in: 100...1000,
                    step: 10
                )
                .tint(.allegroAccent)
                .frame(width: 120)

                Text("\(engine.wpm)")
                    .font(.caption.monospacedDigit())
                    .frame(width: 36, alignment: .leading)

                Spacer()

                Text("\(engine.currentIndex + (engine.tokens.isEmpty ? 0 : 1)) / \(engine.tokens.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var scrubBar: some View {
        Slider(
            value: Binding(
                get: { Double(engine.currentIndex) },
                set: { engine.seek(to: Int($0)) }
            ),
            in: 0...Double(max(engine.tokens.count - 1, 0)),
            step: 1
        )
        .controlSize(.small)
        .disabled(engine.tokens.isEmpty)
    }
}
