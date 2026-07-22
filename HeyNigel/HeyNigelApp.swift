import SwiftUI
import SwiftData

@main
struct HeyNigelApp: App {
    /// UI tests launch with `-UITestReset` so screenshots always start from
    /// a clean onboarding flow, without touching the simulator's real
    /// persisted store.
    private let modelContainer: ModelContainer = {
        let schema = Schema([UserPreferencesRecord.self, ClubYardageRecord.self])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestReset")
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
