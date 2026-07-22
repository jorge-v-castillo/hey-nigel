import SwiftUI

/// A simple, reusable slide for the two "meet Nigel" intro screens that
/// follow the Welcome screen — not voice-driven, just a tap-through
/// introduction before the conversational questions begin.
struct IntroSlideView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button(buttonTitle) { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }
}
