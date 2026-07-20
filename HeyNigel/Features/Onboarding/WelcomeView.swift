import SwiftUI

struct WelcomeView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Hey Nigel")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text("Your voice caddy. Ask for your distance and club, hands-free, right through your AirPods.")
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
