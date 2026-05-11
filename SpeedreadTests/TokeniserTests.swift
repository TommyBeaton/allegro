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
}
