import SwiftUI
import SwiftData

@main
struct HeyNigelApp: App {
    /// UI tests launch with `-UITestReset` so screenshots always start from
    /// a clean onboarding flow, without touching the simulator's real
    /// persisted store.
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            UserPreferencesRecord.self, ClubYardageRecord.self,
            RoundRecord.self, HoleRecord.self,
        ])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestReset")
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // No real users yet, so a schema change that can't open the
            // existing on-disk store is treated as destructive rather than
            // migrated — delete the stale store and start fresh.
            if let storeURL = configuration.url as URL?, !isUITesting {
                try? FileManager.default.removeItem(at: storeURL)
            }
            return try! ModelContainer(for: schema, configurations: [configuration])
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
