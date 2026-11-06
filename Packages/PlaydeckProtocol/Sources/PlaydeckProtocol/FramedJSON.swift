import Foundation

/// Errors from length-prefixed framed JSON codec.
public enum FramedJSONError: Error, Sendable, Equatable {
    case truncatedHeader
    case truncatedPayload(expected: Int, available: Int)
    case payloadTooLarge(Int)
    case invalidUTF8
    case decodingFailed(String)
}

/// 4-byte big-endian length + UTF-8 JSON body.
///
/// Wire format:
/// ```
/// [u32 BE length][utf8 json bytes]
/// ```
public enum FramedJSON {
    public static let maxPayloadBytes = 1_048_576
    public static let headerSize = 4

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Encode a `Codable` value into a single framed packet.
    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        let json = try encoder.encode(value)
        guard json.count <= maxPayloadBytes else {
            throw FramedJSONError.payloadTooLarge(json.count)
        }
        var packet = Data(capacity: headerSize + json.count)
        var length = UInt32(json.count).bigEndian
        withUnsafeBytes(of: &length) { packet.append(contentsOf: $0) }
        packet.append(json)
        return packet
    }

    /// Decode one framed message from the start of `buffer`, returning the value and bytes consumed.
    public static func decode<T: Decodable>(
        _ type: T.Type,
        from buffer: Data
    ) throws -> (value: T, consumed: Int) {
        guard buffer.count >= headerSize else {
            throw FramedJSONError.truncatedHeader
        }
        let header = buffer.prefix(headerSize)
        let length =
            (UInt32(header[header.startIndex]) << 24)
            | (UInt32(header[header.startIndex + 1]) << 16)
            | (UInt32(header[header.startIndex + 2]) << 8)
            | UInt32(header[header.startIndex + 3])
        let payloadLength = Int(length)
        guard payloadLength <= maxPayloadBytes else {
            throw FramedJSONError.payloadTooLarge(payloadLength)
        }
        let total = headerSize + payloadLength
        guard buffer.count >= total else {
            throw FramedJSONError.truncatedPayload(
                expected: payloadLength,
                available: buffer.count - headerSize
            )
        }
        let payload = buffer.subdata(in: headerSize..<total)
        do {
            let value = try decoder.decode(T.self, from: payload)
            return (value, total)
        } catch {
            throw FramedJSONError.decodingFailed(String(describing: error))
        }
    }
}

/// Incremental reader that accumulates bytes until full frames are available.
public final class FramedJSONReader: @unchecked Sendable {
    private var buffer = Data()
    private let lock = NSLock()

    public init() {}

    public func append(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        buffer.append(data)
    }

    /// Drain all complete `PlaydeckEnvelope` frames currently buffered.
    public func drainEnvelopes() throws -> [PlaydeckEnvelope] {
        lock.lock()
        defer { lock.unlock() }
        var messages: [PlaydeckEnvelope] = []
        while true {
            guard buffer.count >= FramedJSON.headerSize else { break }
            do {
                let (value, consumed) = try FramedJSON.decode(
                    PlaydeckEnvelope.self,
                    from: buffer
                )
                buffer.removeFirst(consumed)
                messages.append(value)
            } catch FramedJSONError.truncatedHeader, FramedJSONError.truncatedPayload {
                break
            }
        }
        return messages
    }
}
