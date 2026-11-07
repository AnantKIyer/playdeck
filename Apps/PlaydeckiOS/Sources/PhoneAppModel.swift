import Foundation
import Combine
import PlaydeckProtocol

@MainActor
final class PhoneAppModel: ObservableObject {
    @Published var mode: AppMode = .none
    @Published var role: DeviceRole = .companion
    @Published var accountPath: AccountPath = .localOnly
    @Published var pairingStatus: String = "Not paired"
    @Published var isSignedInWithApple: Bool = false
    @Published var layout: DeckLayout
    @Published var rideState: RideState

    let deviceId: String
    let modeController: ModeController
    private let pairing: PairingSessionStub
    private var cloudStub: any CloudKitAccountStubbing

    init() {
        let id = UserDefaults.standard.string(forKey: "playdeck.deviceId")
            ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: "playdeck.deviceId")
        self.deviceId = id
        self.modeController = ModeController()
        self.pairing = PairingSessionStub(
            localDeviceId: id,
            localRole: .companion,
            displayName: "Playdeck"
        )
        self.cloudStub = LocalOnlyAccountStub()
        self.layout = Self.sampleDenseLayout()
        self.rideState = Self.sampleRideState()

        modeController.onChange { [weak self] newMode in
            Task { @MainActor in
                self?.mode = newMode
            }
        }
    }

    func enterDeck() {
        _ = modeController.enter(.deck)
    }

    func enterRide() {
        _ = modeController.enter(.ride)
    }

    func leaveMode() {
        _ = modeController.leave()
    }

    /// USB / Mac ModeSuggest.deck — refused while Ride is active.
    func applyModeSuggest(_ payload: PlaydeckEnvelope.ModeSuggestPayload) {
        _ = modeController.applySuggest(
            payload.suggest,
            respectRideExclusion: payload.respectRideExclusion
        )
    }

    func startLocalPairing() {
        accountPath = .localOnly
        cloudStub = LocalOnlyAccountStub()
        let handshake = pairing.makeHandshake(nearbyCode: Self.randomNearbyCode())
        pairingStatus = "Local code \(handshake.nearbyCode ?? "????") — waiting for peer"
        // Scaffold: pretend Mac answered.
        let peer = PairingHandshake(
            deviceId: "mac-stub",
            displayName: "Playdeck Mac",
            role: .mac,
            accountPathPreference: .localOnly
        )
        let complete = pairing.complete(with: peer)
        pairingStatus = "Paired locally · session \(complete.sessionId.prefix(8))"
    }

    func chooseAppleIDPath() async {
        accountPath = .appleIDCloudKit
        let stub = AppleIDCloudKitAccountStub()
        do {
            try await stub.signInWithAppleStub()
            try await stub.syncLayoutsStub([layout])
            cloudStub = stub
            isSignedInWithApple = true
            pairingStatus = "Sign in with Apple + CloudKit stub signed in"
        } catch {
            pairingStatus = "Apple ID stub failed: \(error.localizedDescription)"
        }
    }

    func invokeButton(_ button: DeckButton, phase: DeckInvokePhase) {
        guard mode == .deck else { return }
        let pageId = layout.pages.first?.id ?? "page"
        let invoke = DeckInvoke(
            pageId: pageId,
            buttonId: button.id,
            phase: phase
        )
        // Scaffold: would send FramedJSON over Bonjour session to Mac.
        NSLog("DeckInvoke %@", String(describing: invoke))
    }

    private static func randomNearbyCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }

    private static func sampleDenseLayout() -> DeckLayout {
        let colors = ["#3D5A5B", "#C45C26", "#2F6FED", "#5B8C5A", "#6B4C7A", "#1E1E1E"]
        var buttons: [DeckButton] = []
        let columns = 5
        let rows = 3
        for row in 0..<rows {
            for col in 0..<columns {
                let idx = row * columns + col
                buttons.append(
                    DeckButton(
                        title: "B\(idx + 1)",
                        colorHex: colors[idx % colors.count],
                        iconName: "square.grid.3x3.fill",
                        action: DeckAction(kind: .keyChord, payload: "cmd+shift+p")
                    )
                )
            }
        }
        let page = DeckPage(
            name: "Work",
            columns: columns,
            rows: rows,
            buttons: buttons
        )
        return DeckLayout(name: "Default", pages: [page])
    }

    private static func sampleRideState() -> RideState {
        RideState(
            nowPlaying: RideNowPlaying(
                title: "Scaffold Track",
                artist: "Playdeck",
                source: .youtubeMusic,
                isPlaying: true,
                elapsedSeconds: 42,
                durationSeconds: 210
            ),
            trip: RideTripCard(
                destination: "Studio",
                etaText: "14 min",
                nextTurnText: "Right on Market St",
                provider: .appleMaps,
                deepLinkURL: "http://maps.apple.com/?daddr=Studio"
            ),
            alerts: [
                RideAlertTile(
                    title: "Calendar",
                    body: "Standup in 20m",
                    sourceApp: "Playdeck"
                ),
            ]
        )
    }
}
