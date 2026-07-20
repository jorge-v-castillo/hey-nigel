import SwiftUI
import CoreLocation
import Speech

struct PermissionsView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Nigel needs a few permissions")
                .font(.title2.bold())
            Text("These have to be granted now — a voice request through Siri or AirPods can't pop up a permission sheet mid-round.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            permissionRow(
                title: "Location",
                subtitle: "To know which hole you're on and your distance to the green.",
                granted: viewModel.permissions.locationStatus == .authorizedAlways
            ) {
                if viewModel.permissions.locationStatus == .notDetermined {
                    viewModel.permissions.requestLocationWhenInUse()
                } else if viewModel.permissions.locationStatus == .authorizedWhenInUse {
                    viewModel.permissions.requestLocationAlways()
                }
            }

            permissionRow(
                title: "Microphone",
                subtitle: "To hear your question when you press the AirPods control.",
                granted: viewModel.permissions.microphoneGranted
            ) {
                Task { await viewModel.permissions.requestMicrophone() }
            }

            permissionRow(
                title: "Speech Recognition",
                subtitle: "To transcribe what you say into a question Nigel can answer.",
                granted: viewModel.permissions.speechStatus == .authorized
            ) {
                Task { await viewModel.permissions.requestSpeechRecognition() }
            }

            Spacer()

            Button("Continue") { viewModel.advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }

    private func permissionRow(title: String, subtitle: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(granted ? "Granted" : "Allow") { action() }
                .buttonStyle(.bordered)
                .disabled(granted)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
