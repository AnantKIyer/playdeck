import Foundation

/// Music source priority for Ride MVP: YouTube Music / YouTube first, then Apple Music.
public enum RideMusicSource: String, Codable, Sendable, Hashable {
    case youtubeMusic
    case youtube
    case appleMusic
}

/// Navigation provider on the primary phone.
public enum RideMapsProvider: String, Codable, Sendable, Hashable {
    case appleMaps
    case googleMaps
}

/// Transport command from companion → primary.
public enum RideTransportCommand: String, Codable, Sendable, Hashable {
    case playPause
    case next
    case previous
    case seek
    case setVolume
}

public struct RideNowPlaying: Codable, Sendable, Hashable, Equatable {
    public var title: String
    public var artist: String?
    public var source: RideMusicSource
    public var isPlaying: Bool
    public var elapsedSeconds: Double?
    public var durationSeconds: Double?

    public init(
        title: String,
        artist: String? = nil,
        source: RideMusicSource,
        isPlaying: Bool,
        elapsedSeconds: Double? = nil,
        durationSeconds: Double? = nil
    ) {
        self.title = title
        self.artist = artist
        self.source = source
        self.isPlaying = isPlaying
        self.elapsedSeconds = elapsedSeconds
        self.durationSeconds = durationSeconds
    }
}

/// Trip card published by the primary (not live Apple Maps turn API).
public struct RideTripCard: Codable, Sendable, Hashable, Equatable {
    public var destination: String?
    public var etaText: String?
    public var nextTurnText: String?
    public var provider: RideMapsProvider
    public var deepLinkURL: String?

    public init(
        destination: String? = nil,
        etaText: String? = nil,
        nextTurnText: String? = nil,
        provider: RideMapsProvider,
        deepLinkURL: String? = nil
    ) {
        self.destination = destination
        self.etaText = etaText
        self.nextTurnText = nextTurnText
        self.provider = provider
        self.deepLinkURL = deepLinkURL
    }
}

/// App-mediated alert tile (not full Notification Center mirror).
public struct RideAlertTile: Codable, Sendable, Hashable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var body: String?
    public var sourceApp: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        body: String? = nil,
        sourceApp: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.sourceApp = sourceApp
        self.createdAt = createdAt
    }
}

/// Snapshot (+ later deltas) of Ride state from primary → companion.
public struct RideState: Codable, Sendable, Hashable, Equatable {
    public var sessionId: String
    public var nowPlaying: RideNowPlaying?
    public var trip: RideTripCard?
    public var alerts: [RideAlertTile]
    public var updatedAt: Date

    public init(
        sessionId: String = UUID().uuidString,
        nowPlaying: RideNowPlaying? = nil,
        trip: RideTripCard? = nil,
        alerts: [RideAlertTile] = [],
        updatedAt: Date = Date()
    ) {
        self.sessionId = sessionId
        self.nowPlaying = nowPlaying
        self.trip = trip
        self.alerts = alerts
        self.updatedAt = updatedAt
    }
}

public struct RideTransportRequest: Codable, Sendable, Hashable, Equatable {
    public var command: RideTransportCommand
    public var seekSeconds: Double?
    public var volume: Double?

    public init(
        command: RideTransportCommand,
        seekSeconds: Double? = nil,
        volume: Double? = nil
    ) {
        self.command = command
        self.seekSeconds = seekSeconds
        self.volume = volume
    }
}
