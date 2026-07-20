import SwiftUI
import SwiftData

/// Routes between onboarding and the (placeholder, for now) home screen based
/// on whether `UserPreferencesRecord.onboardingCompleted` has been persisted.
/// `@Query` re-evaluates automatically once `OnboardingViewModel.complete`
/// saves that flag, so no manual navigation state is needed here.
struct RootView: View {
    @Query private var preferences: [UserPreferencesRecord]

    var body: some View {
        if preferences.first?.onboardingCompleted == true {
            ContentView()
        } else {
            OnboardingContainerView(courseDataProvider: AppDependencies.shared.courseDataProvider) {}
        }
    }
}
