import XCTest
@testable import PlaydeckProtocol

final class FramedJSONTests: XCTestCase {
    func testRoundTripEnvelope() throws {
        let envelope = PlaydeckEnvelope.deckInvoke(
            DeckInvoke(pageId: "p1", buttonId: "b1", phase: .down)
        )
        let packet = try FramedJSON.encode(envelope)
        let (decoded, consumed) = try FramedJSON.decode(
            PlaydeckEnvelope.self,
            from: packet
        )
        XCTAssertEqual(consumed, packet.count)
        guard case .deckInvoke(let invoke) = decoded else {
            return XCTFail("expected deckInvoke")
        }
        XCTAssertEqual(invoke.pageId, "p1")
        XCTAssertEqual(invoke.buttonId, "b1")
        XCTAssertEqual(invoke.phase, .down)
    }

    func testReaderDrainsMultipleFrames() throws {
        let reader = FramedJSONReader()
        let a = PlaydeckEnvelope.heartbeat(
            .init(deviceId: "d1", mode: .deck)
        )
        let b = PlaydeckEnvelope.modeSuggest(
            .init(suggest: .deck, reason: "usb")
        )
        reader.append(try FramedJSON.encode(a))
        reader.append(try FramedJSON.encode(b))
        let messages = try reader.drainEnvelopes()
        XCTAssertEqual(messages.count, 2)
    }

    func testTruncatedHeaderThrows() {
        XCTAssertThrowsError(
            try FramedJSON.decode(PlaydeckEnvelope.self, from: Data([0, 0]))
        ) { error in
            XCTAssertEqual(error as? FramedJSONError, .truncatedHeader)
        }
    }
}
