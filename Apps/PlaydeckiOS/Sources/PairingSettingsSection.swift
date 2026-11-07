import SwiftUI
import PlaydeckProtocol

struct PairingSettingsSection: View {
    @EnvironmentObject private var model: PhoneAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts & pairing")
                .font(.headline)
            Text(model.pairingStatus)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Choose local pairing, or Sign in with Apple + CloudKit for layout backup. Live control always uses the local mesh.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Pair locally (QR / nearby code stub)") {
                model.startLocalPairing()
            }
            .buttonStyle(.borderedProminent)

            Button("Sign in with Apple + CloudKit (stub)") {
                Task { await model.chooseAppleIDPath() }
            }
            .buttonStyle(.bordered)

            if model.isSignedInWithApple {
                Label("Apple ID path active (stub)", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            Picker("Role", selection: $model.role) {
                Text("Companion").tag(DeviceRole.companion)
                Text("Primary").tag(DeviceRole.primaryPhone)
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
