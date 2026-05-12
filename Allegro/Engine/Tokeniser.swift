import Foundation

struct Token: Equatable {
    let text: String
    let orpIndex: Int
    let baseMultiplier: Double
}

enum Tokeniser {
    /// Split input on whitespace and produce per-token rendering + timing metadata.
    static func tokenise(_ input: String) -> [Token] {
        let pausePunct = UserDefaults.standard.object(forKey: DefaultsKey.pauseOnPunctuation) as? Bool
            ?? DefaultsValue.pauseOnPunctuation

        let pieces = input
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        return pieces.compactMap { raw -> Token? in
            guard !raw.isEmpty else { return nil }
            return Token(
                text: raw,
                orpIndex: orpIndex(for: raw),
                baseMultiplier: durationMultiplier(for: raw, pauseOnPunctuation: pausePunct)
            )
        }
    }

    static func orpIndex(for word: String) -> Int {
        let n = word.count
        switch n {
        case 0...1: return 0
        case 2...5: return 1
        case 6...9: return 2
        case 10...13: return 3
        default: return 4
        }
    }

    /// Per-token delay multiplier — longer dwell on long words and, when enabled,
    /// punctuation breaks.
    static func durationMultiplier(for word: String, pauseOnPunctuation: Bool = true) -> Double {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        var m = 1.0
        if word.count > 8 { m *= 1.3 }
        if pauseOnPunctuation, let last = trimmed.last {
            if last == "," || last == ";" || last == ":" { m *= 1.5 }
            if last == "." || last == "!" || last == "?" { m *= 2.0 }
        }
        return m
    }
}
