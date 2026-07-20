import SwiftUI
import SwiftData

@main
struct HeyNigelApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserPreferencesRecord.self, ClubYardageRecord.self])
    }
}
