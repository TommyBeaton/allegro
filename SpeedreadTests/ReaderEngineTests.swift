import XCTest
@testable import Speedread

@MainActor
final class ReaderEngineTests: XCTestCase {
    func testLoadEmptyStaysIdle() {
        let e = ReaderEngine(wpm: 300)
        e.load("   ", autoPlay: true)
        XCTAssertTrue(e.tokens.isEmpty)
        XCTAssertEqual(e.state, .idle)
    }

    func testLoadAutoPlayMovesToPlaying() {
        let e = ReaderEngine(wpm: 300)
        e.load("alpha beta gamma", autoPlay: true)
        XCTAssertEqual(e.tokens.count, 3)
        XCTAssertEqual(e.state, .playing)
        XCTAssertEqual(e.currentIndex, 0)
        e.pause()
    }

    func testPauseThenResumePreservesIndex() {
        let e = ReaderEngine(wpm: 300)
        e.load("one two three four five", autoPlay: false)
        XCTAssertEqual(e.state, .paused)
        e.step(by: 2)
        XCTAssertEqual(e.currentIndex, 2)
        e.play()
        e.pause()
        XCTAssertEqual(e.currentIndex, 2)
    }

    func testSeekClamps() {
        let e = ReaderEngine(wpm: 300)
        e.load("a b c d", autoPlay: false)
        e.seek(to: 999)
        XCTAssertEqual(e.currentIndex, 3)
        e.seek(to: -10)
        XCTAssertEqual(e.currentIndex, 0)
    }

    func testStepClamps() {
        let e = ReaderEngine(wpm: 300)
        e.load("a b c", autoPlay: false)
        e.step(by: -5)
        XCTAssertEqual(e.currentIndex, 0)
        e.step(by: 100)
        XCTAssertEqual(e.currentIndex, 2)
    }

    func testSetWPMBoundsAreClamped() {
        let e = ReaderEngine(wpm: 300)
        e.setWPM(5)
        XCTAssertEqual(e.wpm, 50)
        e.setWPM(99999)
        XCTAssertEqual(e.wpm, 1500)
    }

    func testTogglePlayPauseCycles() {
        let e = ReaderEngine(wpm: 300)
        e.load("x y z", autoPlay: false)
        XCTAssertEqual(e.state, .paused)
        e.togglePlayPause()
        XCTAssertEqual(e.state, .playing)
        e.togglePlayPause()
        XCTAssertEqual(e.state, .paused)
    }
}
