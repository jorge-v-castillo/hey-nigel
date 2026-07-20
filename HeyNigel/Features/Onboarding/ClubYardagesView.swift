import SwiftUI

struct ClubYardagesView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("About how far do you hit these?")
                .font(.title2.bold())
            Text("Just three clubs for now — Nigel fills in the rest of your bag from these.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            yardageField(label: "Driver", text: Binding(
                get: { viewModel.driverYardageText },
                set: { viewModel.driverYardageText = $0 }
            ))
            yardageField(label: "7 Iron", text: Binding(
                get: { viewModel.sevenIronYardageText },
                set: { viewModel.sevenIronYardageText = $0 }
            ))
            yardageField(label: "Wedge", text: Binding(
                get: { viewModel.wedgeYardageText },
                set: { viewModel.wedgeYardageText = $0 }
            ))

            Spacer()

            Button("Continue") { viewModel.advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canAdvanceFromClubYardages)
        }
        .padding()
    }

    private func yardageField(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 90, alignment: .leading)
            TextField("Yards", text: text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
        }
        .padding(.horizontal)
    }
}
