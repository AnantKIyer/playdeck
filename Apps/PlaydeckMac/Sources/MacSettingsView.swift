import SwiftUI

struct MacSettingsView: View {
    @EnvironmentObject private var model: MacAppModel

    var body: some View {
        Form {
            Section("USB → Deck") {
                Toggle(
                    "Open Deck when connected by cable",
                    isOn: $model.openDeckOnUSB
                )
                Text("When on, a paired iPhone USB attach sends ModeSuggest.deck (skipped if Ride is active).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                LabeledContent("Accessibility") {
                    Text(model.accessibilityReady ? "Granted" : "Required")
                }
                Button("Recheck Accessibility") {
                    model.accessibilityReady = model.accessibility.checkPermission()
                }
                Text("Key chords and UI presses need Accessibility. Automation prompts appear per-app when AppleScript actions are added.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Distribution") {
                Text("Mac helper ships as a notarized direct-download DMG — not Mac App Store — so Accessibility + Automation stay fully available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
