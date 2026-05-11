import XCTest
@testable import Speedread

final class TokeniserTests: XCTestCase {
    func testSplitsOnWhitespace() {
        let tokens = Tokeniser.tokenise("hello   world\nfoo\tbar")
        XCTAssertEqual(tokens.map(\.text), ["hello", "world", "foo", "bar"])
    }

    func testEmptyInputProducesNoTokens() {
        XCTAssertTrue(Tokeniser.tokenise("").isEmpty)
        XCTAssertTrue(Tokeniser.tokenise("   \n  ").isEmpty)
    }

    func testORPIndexBuckets() {
        XCTAssertEqual(Tokeniser.orpIndex(for: "a"), 0)
        XCTAssertEqual(Tokeniser.orpIndex(for: "ab"), 1)
        XCTAssertEqual(Tokeniser.orpIndex(for: "hello"), 1)
        XCTAssertEqual(Tokeniser.orpIndex(for: "running"), 2)
        XCTAssertEqual(Tokeniser.orpIndex(for: "abstraction"), 3)
        XCTAssertEqual(Tokeniser.orpIndex(for: "incomprehensible"), 4)
    }

    func testPunctuationLengthensDelay() {
        let plain = Tokeniser.durationMultiplier(for: "word")
        let comma = Tokeniser.durationMultiplier(for: "word,")
        let period = Tokeniser.durationMultiplier(for: "word.")
        XCTAssertEqual(plain, 1.0, accuracy: 0.0001)
        XCTAssertGreaterThan(comma, plain)
        XCTAssertGreaterThan(period, comma)
    }

    func testLongWordLengthensDelay() {
        XCTAssertGreaterThan(
            Tokeniser.durationMultiplier(for: "abstraction"),
            Tokeniser.durationMultiplier(for: "short")
        )
    }

    func testSentenceTerminatorsLongerThanClauseBreaks() {
        // ! and ? get the sentence-end (×2) multiplier; , ; : only ×1.5.
        let period = Tokeniser.durationMultiplier(for: "word.")
        let bang = Tokeniser.durationMultiplier(for: "word!")
        let question = Tokeniser.durationMultiplier(for: "word?")
        let semicolon = Tokeniser.durationMultiplier(for: "word;")
        let colon = Tokeniser.durationMultiplier(for: "word:")
        XCTAssertEqual(period, bang, accuracy: 0.0001)
        XCTAssertEqual(period, question, accuracy: 0.0001)
        XCTAssertEqual(semicolon, colon, accuracy: 0.0001)
        XCTAssertGreaterThan(period, semicolon)
    }

    func testMixedWhitespaceSeparators() {
        let tokens = Tokeniser.tokenise("a\nb\tc  d\r\ne")
        XCTAssertEqual(tokens.map(\.text), ["a", "b", "c", "d", "e"])
    }

    func testORPLongestBucket() {
        // Anything ≥14 characters falls into the orp=4 bucket.
        XCTAssertEqual(Tokeniser.orpIndex(for: "fourteen-chars"), 4)         // 14 chars
        XCTAssertEqual(Tokeniser.orpIndex(for: "supercalifragilisticexpialidocious"), 4)
    }

    func testTokensCarryORPAndMultiplierTogether() {
        let token = Tokeniser.tokenise("End.").first!
        XCTAssertEqual(token.text, "End.")
        XCTAssertEqual(token.orpIndex, 1)             // 4 chars → bucket 2…5
        XCTAssertEqual(token.baseMultiplier, 2.0, accuracy: 0.0001)
    }
}
