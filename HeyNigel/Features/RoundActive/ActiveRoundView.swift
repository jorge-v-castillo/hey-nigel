import SwiftUI
import HeyNigelCore

/// In-round content only — course/tee/holes setup now lives in
/// `RoundSetupCoordinator`, triggered from `DashboardView`'s "Begin Round"
/// button. All dependencies are injected (constructed once by
/// `DashboardView`) rather than owned here, so there's a single composition
/// point and a single shared mic session.
struct ActiveRoundView: View {
    var roundSession: RoundSessionManager
    var voiceCoordinator: VoiceInputCoordinator
    var guidedPrompt: GuidedVoicePromptCoordinator
    let onEndRound: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let pendingHole = roundSession.pendingHoleChange,
               voiceCoordinator.state == .idle,
               guidedPrompt.phase == .idle {
                GuidedVoicePromptView(coordinator: guidedPrompt)
                    .task(id: pendingHole) {
                        await confirmHoleChange(pendingHole: pendingHole)
                    }
            } else if let round = roundSession.activeRound {
                activeRoundContent(round: round)
            }
        }
        .padding()
    }

    private func confirmHoleChange(pendingHole: Int) async {
        let answer = await guidedPrompt.ask("Looks like we're on the next hole, is that correct?", expecting: .yesNo)
        switch answer {
        case .yesNo(true):
            roundSession.confirmPendingHoleChange(accepted: true)
        case .yesNo(false):
            let correction = await guidedPrompt.ask("What hole are you actually on?", expecting: .number(range: 1...18))
            if case .number(let value) = correction {
                roundSession.confirmPendingHoleChange(accepted: false, correctedHoleNumber: Int(value))
            } else {
                roundSession.confirmPendingHoleChange(accepted: false)
            }
        default:
            roundSession.confirmPendingHoleChange(accepted: false)
        }
    }

    @ViewBuilder
    private func activeRoundContent(round: Round) -> some View {
        Text("Hole \(round.currentHoleNumber)")
            .font(.system(size: 48, weight: .bold, design: .rounded))

        if let phrase = roundSession.spokenPhrase {
            Text(phrase)
                .multilineTextAlignment(.center)
                .padding()
        } else if roundSession.isRefreshing {
            ProgressView()
        } else {
            Text("Waiting for a GPS fix\u{2026}")
                .foregroundStyle(.secondary)
        }

        voiceStatusText

        Button(voiceButtonTitle) {
            voiceCoordinator.startListening()
        }
        .buttonStyle(.borderedProminent)
        .disabled(voiceCoordinator.state != .idle)

        Spacer()

        Button("End Round") {
            onEndRound()
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var voiceStatusText: some View {
        switch voiceCoordinator.state {
        case .idle:
            Text("Press the AirPods stem, or tap below, to ask a question.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .listening:
            Text("Listening\u{2026} \(voiceCoordinator.lastTranscript ?? "")")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .processing:
            Text("Thinking\u{2026}")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .speaking:
            Text("Speaking\u{2026}")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var voiceButtonTitle: String {
        switch voiceCoordinator.state {
        case .idle: return "Hold to Talk"
        case .listening: return "Listening\u{2026}"
        case .processing: return "Thinking\u{2026}"
        case .speaking: return "Speaking\u{2026}"
        }
    }
}
