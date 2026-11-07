import Foundation
import PlaydeckProtocol
import IOKit
import IOKit.usb

struct USBAttachEvent: Sendable {
    enum Kind: String, Sendable {
        case attached
        case detached
        case stubProbe
    }

    var kind: Kind
    var vendorID: Int?
    var productID: Int?
    var note: String

    var description: String {
        let ids: String
        if let vendorID, let productID {
            ids = String(format: "vid=%04x pid=%04x", vendorID, productID)
        } else {
            ids = "unknown ids"
        }
        return "\(kind.rawValue): \(ids) — \(note)"
    }
}

/// Watches USB attach as a stub toward “plug in → ModeSuggest.deck”.
///
/// MVP approach: IOKit USB notifications + later correlate with Bonjour peer on
/// the USB network interface. No custom MFi gadget protocol.
final class USBModeSuggestMonitor {
    private var notificationPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    private var handler: ((USBAttachEvent) -> Void)?
    private let queue = DispatchQueue(label: "playdeck.mac.usb")

    func start(onEvent: @escaping (USBAttachEvent) -> Void) {
        handler = onEvent
        let port = IONotificationPortCreate(kIOMainPortDefault)
        notificationPort = port
        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        let matching = IOServiceMatching(kIOUSBDeviceClassName)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let added: IOServiceMatchingCallback = { refcon, iterator in
            let monitor = Unmanaged<USBModeSuggestMonitor>.fromOpaque(refcon!).takeUnretainedValue()
            monitor.drain(iterator: iterator, kind: .attached)
        }
        let removed: IOServiceMatchingCallback = { refcon, iterator in
            let monitor = Unmanaged<USBModeSuggestMonitor>.fromOpaque(refcon!).takeUnretainedValue()
            monitor.drain(iterator: iterator, kind: .detached)
        }

        IOServiceAddMatchingNotification(
            port,
            kIOMatchedNotification,
            matching,
            added,
            selfPtr,
            &addedIterator
        )
        drain(iterator: addedIterator, kind: .stubProbe)

        // Fresh matching dict required for second registration.
        let matchingRemoved = IOServiceMatching(kIOUSBDeviceClassName)
        IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            matchingRemoved,
            removed,
            selfPtr,
            &removedIterator
        )
        drain(iterator: removedIterator, kind: .detached)

        onEvent(
            USBAttachEvent(
                kind: .stubProbe,
                vendorID: nil,
                productID: nil,
                note: "USB monitor armed (ModeSuggest.deck on attach when paired)"
            )
        )
    }

    func stop() {
        if addedIterator != 0 {
            IOObjectRelease(addedIterator)
            addedIterator = 0
        }
        if removedIterator != 0 {
            IOObjectRelease(removedIterator)
            removedIterator = 0
        }
        if let port = notificationPort {
            IONotificationPortDestroy(port)
            notificationPort = nil
        }
        handler = nil
    }

    /// Test hook for unit/UI previews without real USB hardware.
    func simulatePairedPhoneAttach() {
        handler?(
            USBAttachEvent(
                kind: .attached,
                vendorID: 0x05AC,
                productID: 0x12A8,
                note: "simulated paired iPhone → ModeSuggest.deck"
            )
        )
    }

    private func drain(iterator: io_iterator_t, kind: USBAttachEvent.Kind) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            // Scaffold: emit generic attach. Later filter to paired Apple devices
            // and confirm Bonjour peer on USB bridge interface before ModeSuggest.
            let event = USBAttachEvent(
                kind: kind == .stubProbe ? .stubProbe : kind,
                vendorID: nil,
                productID: nil,
                note: kind == .stubProbe
                    ? "existing USB device enumerated"
                    : "IOKit USB \(kind.rawValue)"
            )
            queue.async { [weak self] in
                self?.handler?(event)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }
}
