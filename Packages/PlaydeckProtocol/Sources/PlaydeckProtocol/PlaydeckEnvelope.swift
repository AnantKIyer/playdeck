import Foundation

/// Top-level framed JSON message envelope shared by all Playdeck peers.
public enum PlaydeckEnvelope: Codable, Sendable, Hashable {
    case hello(Hello)
    case pairingHandshake(PairingHandshake)
    case pairingComplete(PairingComplete)
    case modeSuggest(ModeSuggestPayload)
    case modeChanged(ModeChanged)
    case deckInvoke(DeckInvoke)
    case deckLayoutSync(DeckLayout)
    case rideState(RideState)
    case rideTransport(RideTransportRequest)
    case heartbeat(Heartbeat)
    case goodbye(Goodbye)

    public struct Hello: Codable, Sendable, Hashable {
        public var deviceId: String
        public var displayName: String
        public var role: DeviceRole
        public var protocolVersion: String

        public init(
            deviceId: String,
            displayName: String,
            role: DeviceRole,
            protocolVersion: String = BonjourConstants.protocolVersion
        ) {
            self.deviceId = deviceId
            self.displayName = displayName
            self.role = role
            self.protocolVersion = protocolVersion
        }
    }

    public struct ModeSuggestPayload: Codable, Sendable, Hashable {
        public var suggest: ModeSuggest
        public var reason: String?
        /// When true, phone should refuse if Ride is already active (USB auto-Deck).
        public var respectRideExclusion: Bool

        public init(
            suggest: ModeSuggest,
            reason: String? = nil,
            respectRideExclusion: Bool = true
        ) {
            self.suggest = suggest
            self.reason = reason
            self.respectRideExclusion = respectRideExclusion
        }
    }

    public struct ModeChanged: Codable, Sendable, Hashable {
        public var mode: AppMode
        public var deviceId: String
        public var timestamp: Date

        public init(mode: AppMode, deviceId: String, timestamp: Date = Date()) {
            self.mode = mode
            self.deviceId = deviceId
            self.timestamp = timestamp
        }
    }

    public struct Heartbeat: Codable, Sendable, Hashable {
        public var deviceId: String
        public var mode: AppMode
        public var timestamp: Date

        public init(deviceId: String, mode: AppMode, timestamp: Date = Date()) {
            self.deviceId = deviceId
            self.mode = mode
            self.timestamp = timestamp
        }
    }

    public struct Goodbye: Codable, Sendable, Hashable {
        public var deviceId: String
        public var reason: String?

        public init(deviceId: String, reason: String? = nil) {
            self.deviceId = deviceId
            self.reason = reason
        }
    }
}
