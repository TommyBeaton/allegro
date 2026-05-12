import XCTest
import SwiftUI
import AppKit
@testable import Allegro

final class ColorHexTests: XCTestCase {
    func testParsesSixDigitHex() {
        XCTAssertNotNil(Color(hex: "FFFFFF"))
        XCTAssertNotNil(Color(hex: "000000"))
        XCTAssertNotNil(Color(hex: "D6336C"))
    }

    func testAcceptsLeadingHash() {
        XCTAssertNotNil(Color(hex: "#FFFFFF"))
        XCTAssertNotNil(Color(hex: "#5C29C7"))
    }

    func testTrimsSurroundingWhitespace() {
        XCTAssertNotNil(Color(hex: "  #5C29C7  "))
        XCTAssertNotNil(Color(hex: "\nFFD466\t"))
    }

    func testRejectsInvalidLengths() {
        XCTAssertNil(Color(hex: ""))
        XCTAssertNil(Color(hex: "FFF"))         // 3-digit shorthand unsupported
        XCTAssertNil(Color(hex: "FFFFFFFF"))    // 8-digit unsupported (no alpha)
        XCTAssertNil(Color(hex: "#FF"))
    }

    func testRejectsNonHexCharacters() {
        XCTAssertNil(Color(hex: "GGGGGG"))
        XCTAssertNil(Color(hex: "#ZZZZZZ"))
        XCTAssertNil(Color(hex: "12345 "))      // internal space, not just trim
    }

    func testRGBChannelsRoundTrip() {
        // #5C29C7 = (92, 41, 199) → (0.361, 0.161, 0.780)
        let color = Color(hex: "#5C29C7")!
        let ns = NSColor(color).usingColorSpace(.sRGB)!
        XCTAssertEqual(ns.redComponent,   92.0 / 255, accuracy: 0.005)
        XCTAssertEqual(ns.greenComponent, 41.0 / 255, accuracy: 0.005)
        XCTAssertEqual(ns.blueComponent, 199.0 / 255, accuracy: 0.005)
    }
}
