import SwiftUI
import PlaydeckProtocol

@main
struct PlaydeckiOSApp: App {
    @StateObject private var appModel = PhoneAppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}
