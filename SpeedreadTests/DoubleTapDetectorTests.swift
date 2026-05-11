import XCTest
@testable import Speedread

final class DoubleTapDetectorTests: XCTestCase {
    func testTwoWithinWindowFiresOnce() {
        var clock = Date(timeIntervalSince1970: 0)
        let det = DoubleTapDetector(windowProvider: { 0.5 }, now: { clock })

        XCTAssertFalse(det.register())          // press 1
        clock = clock.addingTimeInterval(0.3)
        XCTAssertTrue(det.register())           // press 2, within 500 ms → fire
    }

    func testTwoOutsideWindowDoesNotFire() {
        var clock = Date(timeIntervalSince1970: 0)
        let det = DoubleTapDetector(windowProvider: { 0.5 }, now: { clock })

        XCTAssertFalse(det.register())          // press 1
        clock = clock.addingTimeInterval(0.8)
        XCTAssertFalse(det.register())          // press 2, too late — starts a new pair
        clock = clock.addingTimeInterval(0.2)
        XCTAssertTrue(det.register())           // press 3, within 500 ms of press 2 → fire
    }

    func testThreeRapidPressesFireExactlyOnce() {
        var clock = Date(timeIntervalSince1970: 0)
        let det = DoubleTapDetector(windowProvider: { 0.5 }, now: { clock })

        XCTAssertFalse(det.register())          // 1
        clock = clock.addingTimeInterval(0.1)
        XCTAssertTrue(det.register())           // 2 — fires
        clock = clock.addingTimeInterval(0.1)
        XCTAssertFalse(det.register())          // 3 — would have fired without reset
    }

    func testWindowReadFreshEachCall() {
        var clock = Date(timeIntervalSince1970: 0)
        var window = 0.2
        let det = DoubleTapDetector(windowProvider: { window }, now: { clock })

        XCTAssertFalse(det.register())
        clock = clock.addingTimeInterval(0.3)
        XCTAssertFalse(det.register())          // outside 200 ms window

        window = 0.5
        clock = clock.addingTimeInterval(0.3)
        XCTAssertTrue(det.register())           // inside the now-widened 500 ms window
    }
}
