import AppKit
import ApplicationServices
import Foundation

/// Minimal Accessibility / CGEvent hello-world for Deck MVP scaffolding.
final class AccessibilityHelloWorld {
    /// Returns whether this process is trusted for Accessibility.
    @discardableResult
    func checkPermission() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    /// Posts a synthetic ⌘⇧P key chord (hello-world — not a product shortcut).
    func postHelloWorldChord() {
        guard checkPermission() else {
            NSLog("Playdeck: Accessibility not granted — cannot synthesize keys")
            return
        }
        postKey(keyCode: 0x23 /* P */, flags: [.maskCommand, .maskShift], keyDown: true)
        postKey(keyCode: 0x23, flags: [.maskCommand, .maskShift], keyDown: false)
    }

    /// Mission Control via public Control+Up key equivalent (stub; Shortcuts preferred later).
    func openMissionControlStub() {
        guard checkPermission() else {
            NSLog("Playdeck: Accessibility not granted — Mission Control stub skipped")
            return
        }
        // Control + Up Arrow (Mission Control default on many layouts).
        postKey(keyCode: 0x7E /* up arrow */, flags: [.maskControl], keyDown: true)
        postKey(keyCode: 0x7E, flags: [.maskControl], keyDown: false)
    }

    private func postKey(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: keyCode,
                keyDown: keyDown
              )
        else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }
}
