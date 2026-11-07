import Foundation
import Combine
import PlaydeckProtocol

@MainActor
final class MacAppModel: ObservableObject {
    @Published var mode: AppMode = .none
    @Published var bonjourStatus: String = "Stopped"
    @Published var lastUSBEvent: String = "None"
    @Published var accessibilityReady: Bool = false
    @Published var openDeckOnUSB: Bool = true

    let deviceId: String
    let modeController: ModeController
    let bonjour: BonjourAdvertiser
    let accessibility: AccessibilityHelloWorld
    let usb: USBModeSuggestMonitor

    init() {
        let id = UserDefaults.standard.string(forKey: "playdeck.deviceId")
            ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: "playdeck.deviceId")
        self.deviceId = id
        self.modeController = ModeController()
        self.bonjour = BonjourAdvertiser(deviceId: id, role: .mac)
        self.accessibility = AccessibilityHelloWorld()
        self.usb = USBModeSuggestMonitor()

        modeController.onChange { [weak self] newMode in
            Task { @MainActor in
                self?.mode = newMode
            }
        }
    }

    func start() {
        bonjour.start { [weak self] status in
            Task { @MainActor in
                self?.bonjourStatus = status
            }
        }
        accessibilityReady = accessibility.checkPermission()
        usb.start { [weak self] event in
            Task { @MainActor in
                self?.handleUSB(event)
            }
        }
    }

    func stop() {
        bonjour.stop()
        usb.stop()
        modeController.leave()
    }

    func enterDeck() {
        _ = modeController.enter(.deck)
        bonjour.broadcast(
            .modeChanged(.init(mode: .deck, deviceId: deviceId))
        )
    }

    func leaveMode() {
        _ = modeController.leave()
        bonjour.broadcast(
            .modeChanged(.init(mode: .none, deviceId: deviceId))
        )
    }

    func runKeyChordHelloWorld() {
        accessibility.postHelloWorldChord()
    }

    func runMissionControlStub() {
        accessibility.openMissionControlStub()
    }

    private func handleUSB(_ event: USBAttachEvent) {
        lastUSBEvent = event.description
        guard openDeckOnUSB else { return }
        guard event.kind == .attached else { return }
        // Do not auto-enter Deck while Ride is active (Ride wins on trip).
        let next = modeController.applySuggest(
            .deck,
            respectRideExclusion: true
        )
        if next == .deck {
            bonjour.broadcast(
                .modeSuggest(
                    .init(
                        suggest: .deck,
                        reason: "usb-attach",
                        respectRideExclusion: true
                    )
                )
            )
        }
    }
}
