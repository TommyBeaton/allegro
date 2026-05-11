import SwiftUI

/// Renders the current word with the ORP character coloured and aligned
/// to a vertical guide line. Slot widths are fixed (longest token in the
/// stream sets the width) so the ORP never jumps horizontally.
struct RSVPView: View {
    @ObservedObject var engine: ReaderEngine
    @AppStorage(DefaultsKey.fontSize) private var fontSize: Double = DefaultsValue.fontSize
    @AppStorage(DefaultsKey.orpColorHex) private var orpColorHex: String = DefaultsValue.orpColorHex

    private var font: Font { .system(size: fontSize, weight: .medium, design: .monospaced) }
    private var orpColor: Color { Color(hex: orpColorHex) ?? .pink }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Vertical guide line where the ORP character sits.
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 1)

                if let token = engine.currentToken {
                    wordView(token)
                } else {
                    Text("—")
                        .font(font)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(minHeight: fontSize * 2.2)
    }

    @ViewBuilder
    private func wordView(_ token: Token) -> some View {
        let chars = Array(token.text)
        let orp = min(token.orpIndex, max(chars.count - 1, 0))
        let before = chars.prefix(orp).map(String.init).joined()
        let pivot = chars.indices.contains(orp) ? String(chars[orp]) : ""
        let after = chars.suffix(from: min(orp + 1, chars.count)).map(String.init).joined()

        HStack(spacing: 0) {
            Text(before)
                .font(font)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(pivot)
                .font(font)
                .foregroundStyle(orpColor)
            Text(after)
                .font(font)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
