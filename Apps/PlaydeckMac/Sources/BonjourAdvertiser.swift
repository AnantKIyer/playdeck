import Foundation
import Network
import PlaydeckProtocol

/// Advertises `_playdeck._tcp` and holds peer connections for framed JSON.
final class BonjourAdvertiser: @unchecked Sendable {
    private let deviceId: String
    private let role: DeviceRole
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let queue = DispatchQueue(label: "playdeck.mac.bonjour")
    private var statusHandler: ((String) -> Void)?

    init(deviceId: String, role: DeviceRole) {
        self.deviceId = deviceId
        self.role = role
    }

    func start(status: @escaping (String) -> Void) {
        statusHandler = status
        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            let listener = try NWListener(using: parameters)
            listener.service = NWListener.Service(
                name: "Playdeck Mac",
                type: BonjourConstants.serviceType,
                txtRecord: NWTXTRecord([
                    BonjourConstants.txtRoleKey: role.rawValue,
                    BonjourConstants.txtVersionKey: BonjourConstants.protocolVersion,
                    "id": deviceId,
                ])
            )
            listener.stateUpdateHandler = { [weak self] state in
                let text: String
                switch state {
                case .ready: text = "Advertising \(BonjourConstants.serviceType)"
                case .failed(let error): text = "Failed: \(error)"
                case .cancelled: text = "Stopped"
                default: text = "\(state)"
                }
                self?.statusHandler?(text)
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.start(queue: queue)
            self.listener = listener
            status("Starting…")
        } catch {
            status("Listener error: \(error.localizedDescription)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        connections.forEach { $0.cancel() }
        connections.removeAll()
        statusHandler?("Stopped")
    }

    func broadcast(_ envelope: PlaydeckEnvelope) {
        guard let data = try? FramedJSON.encode(envelope) else { return }
        for connection in connections {
            connection.send(
                content: data,
                completion: .contentProcessed { _ in }
            )
        }
    }

    private func accept(_ connection: NWConnection) {
        connections.append(connection)
        let reader = FramedJSONReader()
        connection.start(queue: queue)
        receive(on: connection, reader: reader)

        let hello = PlaydeckEnvelope.hello(
            .init(
                deviceId: deviceId,
                displayName: "Playdeck Mac",
                role: role
            )
        )
        if let data = try? FramedJSON.encode(hello) {
            connection.send(content: data, completion: .contentProcessed { _ in })
        }
    }

    private func receive(on connection: NWConnection, reader: FramedJSONReader) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64_000) {
            [weak self] content, _, isComplete, error in
            if let content {
                reader.append(content)
                if let messages = try? reader.drainEnvelopes() {
                    for message in messages {
                        self?.handle(message, from: connection)
                    }
                }
            }
            if isComplete || error != nil {
                connection.cancel()
                self?.connections.removeAll { $0 === connection }
                return
            }
            self?.receive(on: connection, reader: reader)
        }
    }

    private func handle(_ envelope: PlaydeckEnvelope, from connection: NWConnection) {
        switch envelope {
        case .deckInvoke(let invoke):
            // Scaffold: log / later route to DeckExecutor.
            NSLog("DeckInvoke page=%@ button=%@ phase=%@", invoke.pageId, invoke.buttonId, invoke.phase.rawValue)
        case .hello, .pairingHandshake, .pairingComplete, .modeSuggest,
             .modeChanged, .deckLayoutSync, .rideState, .rideTransport,
             .heartbeat, .goodbye:
            break
        }
        _ = connection
    }
}
