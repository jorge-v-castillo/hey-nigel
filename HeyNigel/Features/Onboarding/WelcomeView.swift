import SwiftUI

struct WelcomeView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Hey, Nigel.")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text("Your personal golf caddy. Ask me your distance, club to use, and more all hands free to your earbuds.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button("Get Started") { viewModel.advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }
}
