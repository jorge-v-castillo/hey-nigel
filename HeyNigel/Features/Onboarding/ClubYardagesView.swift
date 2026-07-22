import SwiftUI

/// Hosts the 9-club voice loop: shows progress through the list, the shared
/// `GuidedVoicePromptView` for the current club's question, and an explicit
/// "Skip this club" button (each club is individually skippable — a real
/// golfer's bag rarely has all 9 of these).
struct ClubYardagesView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Let's add your clubs to the bag")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Club \(viewModel.currentClubIndex + 1) of \(viewModel.totalClubCount): \(viewModel.currentClubName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GuidedVoicePromptView(coordinator: viewModel.guidedPrompt)

            if viewModel.guidedPrompt.phase == .waitingForAnswer {
                Button("Skip this club") { viewModel.skipCurrentClub() }
                    .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .task {
            await viewModel.runClubLoop()
        }
    }
}
