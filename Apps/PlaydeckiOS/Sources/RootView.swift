import SwiftUI
import PlaydeckProtocol

struct RootView: View {
    @EnvironmentObject private var model: PhoneAppModel

    var body: some View {
        Group {
            switch model.mode {
            case .none:
                HomeShellView()
            case .deck:
                DeckGridView()
            case .ride:
                RideShellView()
            }
        }
        .animation(.snappy, value: model.mode)
    }
}

struct HomeShellView: View {
    @EnvironmentObject private var model: PhoneAppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playdeck")
                            .font(.largeTitle.weight(.bold))
                        Text("Deck macros on your Mac, or Ride with your primary phone — never both at once.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        ModeLaunchButton(
                            title: "Enter Deck",
                            subtitle: "Dense Stream Deck–style grid → Mac helper",
                            systemImage: "rectangle.grid.3x2.fill"
                        ) {
                            model.enterDeck()
                        }
                        ModeLaunchButton(
                            title: "Enter Ride",
                            subtitle: "Dashboard linked to your primary iPhone",
                            systemImage: "car.side.fill"
                        ) {
                            model.enterRide()
                        }
                    }

                    PairingSettingsSection()
                }
                .padding(20)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ModeLaunchButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
