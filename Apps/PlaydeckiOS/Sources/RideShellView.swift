import SwiftUI
import PlaydeckProtocol

/// CarPlay-*inspired* Ride shell — not real CarPlay. Dual-iPhone MVP.
struct RideShellView: View {
    @EnvironmentObject private var model: PhoneAppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tripCard
                    nowPlayingCard
                    alertsSection
                    Text("Ride is a companion dashboard linked to your primary phone. Not Apple CarPlay.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.12),
                        Color(red: 0.09, green: 0.12, blue: 0.16),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Leave") { model.leaveMode() }
                }
            }
        }
    }

    private var tripCard: some View {
        let trip = model.rideState.trip
        return VStack(alignment: .leading, spacing: 10) {
            Label("Trip", systemImage: "map.fill")
                .font(.headline)
            Text(trip?.destination ?? "No destination")
                .font(.title2.weight(.semibold))
            HStack {
                Text(trip?.etaText ?? "—")
                Spacer()
                Text(trip?.provider == .googleMaps ? "Google Maps" : "Apple Maps")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            if let turn = trip?.nextTurnText {
                Text(turn)
                    .font(.title3)
                    .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var nowPlayingCard: some View {
        let np = model.rideState.nowPlaying
        return VStack(alignment: .leading, spacing: 12) {
            Label(sourceLabel(np?.source), systemImage: "music.note")
                .font(.headline)
            Text(np?.title ?? "Nothing playing")
                .font(.title3.weight(.semibold))
            if let artist = np?.artist {
                Text(artist)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 28) {
                transportButton("backward.fill") { /* previous */ }
                transportButton(np?.isPlaying == true ? "pause.fill" : "play.fill") { /* playPause */ }
                transportButton("forward.fill") { /* next */ }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            Text("MVP priority: YouTube Music / YouTube, then Apple Music.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Alerts", systemImage: "bell.fill")
                .font(.headline)
            Text("App-mediated only — no Notification Center mirror.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(model.rideState.alerts) { alert in
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title).font(.subheadline.weight(.semibold))
                    if let body = alert.body {
                        Text(body).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func transportButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private func sourceLabel(_ source: RideMusicSource?) -> String {
        switch source {
        case .youtubeMusic: return "YouTube Music"
        case .youtube: return "YouTube"
        case .appleMusic: return "Apple Music"
        case .none: return "Now Playing"
        }
    }
}
