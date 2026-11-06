import Foundation

/// Logical role of a node on the Playdeck mesh.
public enum DeviceRole: String, Codable, Sendable, CaseIterable, Hashable {
    case mac
    case primaryPhone
    case companion
}
