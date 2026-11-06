import XCTest
@testable import PlaydeckProtocol

final class ModeControllerTests: XCTestCase {
    func testDeckAndRideAreMutuallyExclusive() {
        let controller = ModeController()
        XCTAssertEqual(controller.enter(.deck), .deck)
        XCTAssertEqual(controller.enter(.ride), .ride)
        XCTAssertEqual(controller.mode, .ride)
        XCTAssertEqual(controller.enter(.deck), .deck)
        XCTAssertEqual(controller.mode, .deck)
    }

    func testLeaveReturnsToNone() {
        let controller = ModeController(initial: .ride)
        XCTAssertEqual(controller.leave(), .none)
    }

    func testUSBSuggestRespectsActiveRide() {
        let controller = ModeController(initial: .ride)
        let result = controller.applySuggest(.deck, respectRideExclusion: true)
        XCTAssertEqual(result, .ride)
    }

    func testUSBSuggestEntersDeckWhenIdle() {
        let controller = ModeController()
        let result = controller.applySuggest(.deck, respectRideExclusion: true)
        XCTAssertEqual(result, .deck)
    }
}
