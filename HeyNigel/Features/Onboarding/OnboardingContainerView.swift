import SwiftUI
import SwiftData
import HeyNigelCourseData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    init(courseDataProvider: HeyNigelCourseData.CourseDataProvider, onComplete: @escaping () -> Void) {
        _viewModel = State(initialValue: OnboardingViewModel(courseDataProvider: courseDataProvider))
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
                    case .courseSearch:
                        CourseSearchView(viewModel: viewModel)
                    case .teeSelection:
                        TeeSelectionView(viewModel: viewModel)
                    case .holeCount:
                        HoleCountView(viewModel: viewModel)
                    case .clubYardages:
                        ClubYardagesView(viewModel: viewModel)
                    case .permissions:
                        PermissionsView(viewModel: viewModel)
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
            .toolbar {
                if viewModel.step != .welcome {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") { viewModel.back() }
                    }
                }
            }
        }
    }
}
