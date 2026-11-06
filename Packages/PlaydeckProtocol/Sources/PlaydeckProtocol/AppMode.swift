import Foundation

/// Active Playdeck environment. Deck and Ride are mutually exclusive.
public enum AppMode: String, Codable, Sendable, CaseIterable, Hashable {
    /// Neither Deck nor Ride is active.
    case none
    /// Desk / Stream Deck–style macros against a Mac helper.
    case deck
    /// Dual-iPhone ride dashboard (CarPlay-inspired; not real CarPlay).
    case ride
}

/// Suggestion from Mac (e.g. USB attach) or peer that the companion enter a mode.
public enum ModeSuggest: String, Codable, Sendable, CaseIterable, Hashable {
    case deck
    case ride
    case neither
}

extension ModeSuggest {
    public var asAppMode: AppMode {
        switch self {
        case .deck: return .deck
        case .ride: return .ride
        case .neither: return .none
        }
    }
}
