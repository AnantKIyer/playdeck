import Foundation

/// Phase of a deck button press.
public enum DeckInvokePhase: String, Codable, Sendable, Hashable {
    case down
    case up
    case hold
}

/// Companion → Mac: invoke a bound deck action.
public struct DeckInvoke: Codable, Sendable, Hashable, Equatable {
    public var pageId: String
    public var buttonId: String
    public var phase: DeckInvokePhase
    public var timestamp: Date

    public init(
        pageId: String,
        buttonId: String,
        phase: DeckInvokePhase,
        timestamp: Date = Date()
    ) {
        self.pageId = pageId
        self.buttonId = buttonId
        self.phase = phase
        self.timestamp = timestamp
    }
}

/// Action kinds the Mac executor can run in MVP (no shell).
public enum DeckActionKind: String, Codable, Sendable, Hashable {
    case keyChord
    case appShortcut
    case systemGesture
    case openURL
    case macro
}

/// Bound action on a deck button (layout asset).
public struct DeckAction: Codable, Sendable, Hashable, Equatable {
    public var kind: DeckActionKind
    /// Bundle ID when targeting a specific app; nil = frontmost.
    public var bundleID: String?
    /// Keyboard equivalent, menu path, Shortcuts name, or URL depending on kind.
    public var payload: String
    public var delayMs: Int?

    public init(
        kind: DeckActionKind,
        bundleID: String? = nil,
        payload: String,
        delayMs: Int? = nil
    ) {
        self.kind = kind
        self.bundleID = bundleID
        self.payload = payload
        self.delayMs = delayMs
    }
}

/// Single button in a dense Stream Deck–style grid.
public struct DeckButton: Codable, Sendable, Hashable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var colorHex: String
    public var iconName: String?
    public var action: DeckAction?

    public init(
        id: String = UUID().uuidString,
        title: String,
        colorHex: String = "#2B2B2B",
        iconName: String? = nil,
        action: DeckAction? = nil
    ) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        self.iconName = iconName
        self.action = action
    }
}

/// One page of dense buttons (e.g. 4×6 / 5×8).
public struct DeckPage: Codable, Sendable, Hashable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var columns: Int
    public var rows: Int
    public var buttons: [DeckButton]

    public init(
        id: String = UUID().uuidString,
        name: String,
        columns: Int = 5,
        rows: Int = 3,
        buttons: [DeckButton] = []
    ) {
        self.id = id
        self.name = name
        self.columns = columns
        self.rows = rows
        self.buttons = buttons
    }
}

/// User deck layout / profile.
public struct DeckLayout: Codable, Sendable, Hashable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var pages: [DeckPage]
    public var updatedAt: Date
    public var updatedByDeviceId: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        pages: [DeckPage] = [],
        updatedAt: Date = Date(),
        updatedByDeviceId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.pages = pages
        self.updatedAt = updatedAt
        self.updatedByDeviceId = updatedByDeviceId
    }
}
