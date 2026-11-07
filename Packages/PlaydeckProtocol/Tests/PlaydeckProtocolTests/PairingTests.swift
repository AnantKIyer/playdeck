import XCTest
@testable import PlaydeckProtocol

final class PairingTests: XCTestCase {
    func testLocalHandshakeCompletes() {
        let session = PairingSessionStub(
            localRole: .companion,
            displayName: "Phone",
            accountPath: .localOnly
        )
        let handshake = session.makeHandshake(nearbyCode: "4242")
        XCTAssertEqual(handshake.nearbyCode, "4242")
        XCTAssertEqual(handshake.role, .companion)

        let peer = PairingHandshake(
            deviceId: "mac-1",
            displayName: "Mac",
            role: .mac,
            accountPathPreference: .localOnly
        )
        let complete = session.complete(with: peer)
        XCTAssertEqual(complete.peerDeviceId, "mac-1")
        XCTAssertEqual(complete.accountPath, .localOnly)
    }

    func testAppleIDStubStoresLayouts() async throws {
        let stub = AppleIDCloudKitAccountStub()
        try await stub.signInWithAppleStub()
        let layout = DeckLayout(name: "Work")
        try await stub.syncLayoutsStub([layout])
        let fetched = try await stub.fetchLayoutsStub()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Work")
    }
}
