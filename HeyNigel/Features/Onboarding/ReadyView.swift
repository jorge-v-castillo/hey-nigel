import SwiftUI
import HeyNigelCore

struct ReadyView: View {
    var viewModel: OnboardingViewModel
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("You're all set")
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 8) {
                summaryRow("Course", viewModel.selectedCourse?.name ?? "—")
                summaryRow("Tees", viewModel.selectedTeeName ?? "—")
                summaryRow("Holes", "\(viewModel.holeCount), starting \(viewModel.startingNine == .front ? "front" : "back") 9")
                if let profile = viewModel.parsedClubProfile {
                    summaryRow("Driver", "\(Int(profile.clubs.first { $0.name == "Driver" }?.averageCarryYards ?? 0)) yds")
                    summaryRow("7 Iron", "\(Int(profile.clubs.first { $0.name == "7 Iron" }?.averageCarryYards ?? 0)) yds")
                    summaryRow("Wedge", "\(Int(profile.clubs.first { $0.name == "Wedge" }?.averageCarryYards ?? 0)) yds")
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            Button("Let's Play") { onStart() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
