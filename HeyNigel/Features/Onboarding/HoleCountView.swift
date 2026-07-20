import SwiftUI
import HeyNigelCore

struct HoleCountView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("How many holes today?")
                .font(.title2.bold())

            Picker("Holes", selection: Binding(
                get: { viewModel.holeCount },
                set: { viewModel.holeCount = $0 }
            )) {
                Text("9").tag(9)
                Text("18").tag(18)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Text("Which nine are you starting on?")
                .font(.headline)

            Picker("Starting nine", selection: Binding(
                get: { viewModel.startingNine },
                set: { viewModel.startingNine = $0 }
            )) {
                Text("Front 9").tag(Nine.front)
                Text("Back 9").tag(Nine.back)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Spacer()

            Button("Continue") { viewModel.advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }
}
