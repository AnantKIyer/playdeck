import SwiftUI
import PlaydeckProtocol

@main
struct PlaydeckMacApp: App {
    @StateObject private var appModel = MacAppModel()

    var body: some Scene {
        MenuBarExtra("Playdeck", systemImage: "rectangle.grid.3x2") {
            MacMenuBarView()
                .environmentObject(appModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            MacSettingsView()
                .environmentObject(appModel)
                .frame(width: 420, height: 320)
        }
    }
}
