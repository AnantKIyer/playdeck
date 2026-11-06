import AppKit
import SwiftUI
import PlaydeckProtocol

struct MacMenuBarView: View {
    @EnvironmentObject private var model: MacAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playdeck")
                .font(.title2.weight(.semibold))

            LabeledContent("Mode") {
                Text(model.mode.rawValue.capitalized)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Bonjour") {
                Text(model.bonjourStatus)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("USB") {
                Text(model.lastUSBEvent)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Divider()

            Button("Start helper services") {
                model.start()
            }
            Button("Enter Deck") {
                model.enterDeck()
            }
            Button("Leave mode") {
                model.leaveMode()
            }

            Divider()

            Group {
                Text("Accessibility hello-world")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Post ⌘⇧P key chord") {
                    model.runKeyChordHelloWorld()
                }
                .disabled(!model.accessibilityReady)
                Button("Mission Control stub") {
                    model.runMissionControlStub()
                }
            }

            Divider()

            SettingsLink {
                Text("Settings…")
            }
            Button("Quit Playdeck") {
                model.stop()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(16)
        .frame(width: 300)
        .onAppear { model.start() }
    }
}
