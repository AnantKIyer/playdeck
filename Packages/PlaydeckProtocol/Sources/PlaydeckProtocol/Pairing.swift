import Foundation

/// Account path chosen by the user.
public enum AccountPath: String, Codable, Sendable, Hashable {
    /// Local QR / nearby code pairing only; layouts stay on-device / local mesh.
    case localOnly
    /// Sign in with Apple + CloudKit private DB for layout backup / multi-device restore.
    case appleIDCloudKit
}

/// Stub Curve25519 public key material (32 bytes). Real crypto lands in a later PR.
public struct PairingPublicKey: Codable, Sendable, Hashable, Equatable {
    public var rawBase64: String

    public init(rawBase64: String) {
        self.rawBase64 = rawBase64
    }

    /// Generates a deterministic-looking stub key for scaffolding / previews.
    public static func stub(seed: String = UUID().uuidString) -> PairingPublicKey {
        let bytes = Array(seed.utf8.prefix(32))
        var padded = bytes
        while padded.count < 32 { padded.append(0) }
        return PairingPublicKey(rawBase64: Data(padded).base64EncodedString())
    }
}

/// First message in local pairing (QR / nearby code).
public struct PairingHandshake: Codable, Sendable, Hashable, Equatable {
    public var deviceId: String
    public var displayName: String
    public var role: DeviceRole
    public var ephemeralPublicKey: PairingPublicKey
    public var nearbyCode: String?
    public var accountPathPreference: AccountPath?

    public init(
        deviceId: String,
        displayName: String,
        role: DeviceRole,
        ephemeralPublicKey: PairingPublicKey = .stub(),
        nearbyCode: String? = nil,
        accountPathPreference: AccountPath? = nil
    ) {
        self.deviceId = deviceId
        self.displayName = displayName
        self.role = role
        self.ephemeralPublicKey = ephemeralPublicKey
        self.nearbyCode = nearbyCode
        self.accountPathPreference = accountPathPreference
    }
}

public struct PairingComplete: Codable, Sendable, Hashable, Equatable {
    public var deviceId: String
    public var peerDeviceId: String
    public var sessionId: String
    public var accountPath: AccountPath
    /// Stub session key id — Keychain storage is app-side.
    public var sessionKeyId: String

    public init(
        deviceId: String,
        peerDeviceId: String,
        sessionId: String = UUID().uuidString,
        accountPath: AccountPath,
        sessionKeyId: String = UUID().uuidString
    ) {
        self.deviceId = deviceId
        self.peerDeviceId = peerDeviceId
        self.sessionId = sessionId
        self.accountPath = accountPath
        self.sessionKeyId = sessionKeyId
    }
}

/// Scaffold pairing coordinator — crypto is stubbed; replace with Noise/TLS later.
public struct PairingSessionStub: Sendable {
    public var localDeviceId: String
    public var localRole: DeviceRole
    public var displayName: String
    public var accountPath: AccountPath
    public var localPublicKey: PairingPublicKey

    public init(
        localDeviceId: String = UUID().uuidString,
        localRole: DeviceRole,
        displayName: String,
        accountPath: AccountPath = .localOnly,
        localPublicKey: PairingPublicKey = .stub()
    ) {
        self.localDeviceId = localDeviceId
        self.localRole = localRole
        self.displayName = displayName
        self.accountPath = accountPath
        self.localPublicKey = localPublicKey
    }

    public func makeHandshake(nearbyCode: String? = nil) -> PairingHandshake {
        PairingHandshake(
            deviceId: localDeviceId,
            displayName: displayName,
            role: localRole,
            ephemeralPublicKey: localPublicKey,
            nearbyCode: nearbyCode,
            accountPathPreference: accountPath
        )
    }

    public func complete(with peer: PairingHandshake) -> PairingComplete {
        PairingComplete(
            deviceId: localDeviceId,
            peerDeviceId: peer.deviceId,
            accountPath: peer.accountPathPreference ?? accountPath
        )
    }
}

/// Placeholder for Sign in with Apple + CloudKit layout sync.
/// Real AuthenticationServices / CloudKit wiring lives in the iOS app target.
public protocol CloudKitAccountStubbing: Sendable {
    var isSignedIn: Bool { get }
    func signInWithAppleStub() async throws
    func syncLayoutsStub(_ layouts: [DeckLayout]) async throws
    func fetchLayoutsStub() async throws -> [DeckLayout]
}

public struct LocalOnlyAccountStub: CloudKitAccountStubbing {
    public var isSignedIn: Bool { false }

    public init() {}

    public func signInWithAppleStub() async throws {
        // Local-only path intentionally no-ops.
    }

    public func syncLayoutsStub(_ layouts: [DeckLayout]) async throws {
        _ = layouts
    }

    public func fetchLayoutsStub() async throws -> [DeckLayout] {
        []
    }
}

public actor AppleIDCloudKitAccountStub: CloudKitAccountStubbing {
    public private(set) var isSignedIn: Bool = false
    private var stored: [DeckLayout] = []

    public init() {}

    public func signInWithAppleStub() async throws {
        // Scaffold: pretend SIWA succeeded. Replace with ASAuthorizationAppleIDProvider.
        isSignedIn = true
    }

    public func syncLayoutsStub(_ layouts: [DeckLayout]) async throws {
        guard isSignedIn else { return }
        stored = layouts
    }

    public func fetchLayoutsStub() async throws -> [DeckLayout] {
        guard isSignedIn else { return [] }
        return stored
    }
}
