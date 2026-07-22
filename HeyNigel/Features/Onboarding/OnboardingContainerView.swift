import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        let guidedPrompt = GuidedVoicePromptCoordinator(
            captureEngine: SpeechCaptureEngine(),
            synthesizer: SpeechSynthesizerService()
        )
        _viewModel = State(initialValue: OnboardingViewModel(guidedPrompt: guidedPrompt))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack {
                ProgressView(value: Double(viewModel.step.rawValue), total: Double(OnboardingStep.allCases.count - 1))
                    .padding(.horizontal)

                Group {
                    switch viewModel.step {
                    case .welcome:
                        WelcomeView(viewModel: viewModel)
                    case .introOne:
                        IntroSlideView(
                            title: "Hello, I'm Nigel",
                            message: "I'll be your personal caddy.",
                            buttonTitle: "Continue"
                        ) { viewModel.advance() }
                    case .introTwo:
                        IntroSlideView(
                            title: "Let's get you set up",
                            message: "To better assist you, I will walk you through a series of questions... let's begin.",
                            buttonTitle: "Let's Begin"
                        ) { viewModel.advance() }
                    case .permissions:
                        PermissionsView(viewModel: viewModel)
                    case .name:
                        GuidedVoicePromptView(coordinator: viewModel.guidedPrompt)
                            .task { await viewModel.runNameStep() }
                    case .nickname:
                        GuidedVoicePromptView(coordinator: viewModel.guidedPrompt)
                            .task { await viewModel.runNicknameStep() }
                    case .clubs:
                        ClubYardagesView(viewModel: viewModel)
                    case .ready:
                        ReadyView(viewModel: viewModel) {
                            viewModel.complete(modelContext: modelContext)
                            onComplete()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Set Up Nigel")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
