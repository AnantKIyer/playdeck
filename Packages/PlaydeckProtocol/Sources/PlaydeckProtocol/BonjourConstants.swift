import Foundation

/// Shared Bonjour / Network.framework constants for Playdeck discovery.
public enum BonjourConstants: Sendable {
    /// TCP service type advertised by Mac helper and discoverable by phones.
    public static let serviceType = "_playdeck._tcp"

    /// Default TCP port for the helper listener (0 = ephemeral at runtime).
    public static let defaultPort: UInt16 = 17_840

    /// TXT record key for device role.
    public static let txtRoleKey = "role"

    /// TXT record key for protocol version.
    public static let txtVersionKey = "v"

    /// Current wire protocol version string.
    public static let protocolVersion = "1"
}
