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
            Text("I've got everything I need — let's head to your dashboard.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                summaryRow("Name", viewModel.fullName.isEmpty ? "—" : viewModel.fullName)
                if let nickname = viewModel.nickname {
                    summaryRow("Nickname", nickname)
                }
                summaryRow("Clubs added", "\(viewModel.clubDrafts.count) of \(viewModel.totalClubCount)")
                ForEach(viewModel.clubDrafts, id: \.name) { club in
                    summaryRow(club.name, "\(Int(club.averageCarryYards)) yds")
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            Button("Continue") { onStart() }
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
