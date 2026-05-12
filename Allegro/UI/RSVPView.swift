import SwiftUI

/// Renders the current word with the ORP character coloured and aligned
/// to a vertical guide line.
struct RSVPView: View {
    @ObservedObject var engine: ReaderEngine
    @AppStorage(DefaultsKey.fontSize) private var fontSize: Double = DefaultsValue.fontSize
    @AppStorage(DefaultsKey.fontFamily) private var fontFamilyRaw: String = DefaultsValue.fontFamily
    @AppStorage(DefaultsKey.orpColorHex) private var orpColorHex: String = DefaultsValue.orpColorHex

    private var family: FontFamily { FontFamily(rawValue: fontFamilyRaw) ?? .mono }
    private var font: Font { .system(size: fontSize, weight: .medium, design: family.design) }
    private var orpColor: Color { Color(hex: orpColorHex) ?? .pink }

    /// Guide line is faint while reading (so words feel uninterrupted), and more
    /// visible when paused (so the user can locate the ORP).
    private var guideOpacity: Double {
        engine.state == .playing ? 0.06 : 0.18
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .fill(Color.primary.opacity(guideOpacity))
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
