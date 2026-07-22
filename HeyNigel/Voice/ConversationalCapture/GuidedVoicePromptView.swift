import SwiftUI
import HeyNigelCore

/// Renders whatever `GuidedVoicePromptCoordinator` is currently doing: the
/// question, a mic button, and a manual fallback control that switches on
/// the expected answer's shape — always visible, not failure-triggered,
/// since speech recognition can mishear a proper name or a yardage just as
/// easily as it can succeed.
struct GuidedVoicePromptView: View {
    var coordinator: GuidedVoicePromptCoordinator
    @State private var manualText: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(coordinator.currentQuestion)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            statusText

            switch coordinator.phase {
            case .idle, .asking:
                EmptyView()
            case .waitingForAnswer, .listening:
                answerControls
            case .reviewing:
                reviewControls
            }
        }
        .padding()
        .onChange(of: coordinator.phase) { _, newPhase in
            if newPhase == .waitingForAnswer {
                manualText = ""
            }
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch coordinator.phase {
        case .listening:
            Text(coordinator.liveTranscript.isEmpty ? "Listening…" : coordinator.liveTranscript)
                .font(.callout)
                .foregroundStyle(.secondary)
        case .asking:
            ProgressView()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var answerControls: some View {
        Button {
            coordinator.startListening()
        } label: {
            Label("Tap to Answer", systemImage: "mic.fill")
        }
        .buttonStyle(.borderedProminent)
        .disabled(coordinator.phase == .listening)

        manualFallback
    }

    @ViewBuilder
    private var manualFallback: some View {
        switch coordinator.currentExpectation {
        case .yesNo:
            HStack(spacing: 16) {
                Button("Yes") { coordinator.resolveDirectly(.yesNo(true)) }
                    .buttonStyle(.bordered)
                Button("No") { coordinator.resolveDirectly(.yesNo(false)) }
                    .buttonStyle(.bordered)
            }
        case .choice(let options):
            VStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button(option) {
                        coordinator.resolveDirectly(.choice(index: index, matched: option))
                    }
                    .buttonStyle(.bordered)
                }
            }
        case .freeText(_), .number(_):
            HStack {
                TextField("Type your answer", text: $manualText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("guidedPromptTextField")
                Button("Submit") {
                    coordinator.submitManualAnswer(manualText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manualText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var reviewControls: some View {
        VStack(spacing: 12) {
            Text("Did I get that right?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Answer", text: Binding(
                get: { coordinator.reviewText },
                set: { coordinator.reviewText = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
            if let error = coordinator.reviewError {
                Text(error).foregroundStyle(.red).font(.caption)
            }
            HStack(spacing: 16) {
                Button("Try Again") { coordinator.cancelReviewAndRetry() }
                    .buttonStyle(.bordered)
                Button("Confirm") { coordinator.confirmReview() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
