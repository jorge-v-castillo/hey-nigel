import Foundation
import SwiftData
import HeyNigelCore

/// Explicit mapping between SwiftData `@Model` records and `HeyNigelCore`'s
/// plain Codable structs — keeps Core dependency-free while still letting the
/// rest of the app work in terms of its clean domain types.
extension UserPreferencesRecord {
    var startingNine: Nine? {
        get { startingNineRaw.flatMap(Nine.init(rawValue:)) }
        set { startingNineRaw = newValue?.rawValue }
    }

    var clubProfile: PlayerClubProfile {
        PlayerClubProfile(clubs: clubYardages.map {
            ClubYardage(name: $0.name, averageCarryYards: $0.averageCarryYards, order: $0.order)
        })
    }

    func replaceClubProfile(_ profile: PlayerClubProfile, in context: ModelContext) {
        for record in clubYardages {
            context.delete(record)
        }
        clubYardages = profile.clubs.map {
            ClubYardageRecord(name: $0.name, averageCarryYards: $0.averageCarryYards, order: $0.order)
        }
    }
}

enum UserPreferencesStore {
    /// Fetches the single preferences record, creating it if this is the
    /// very first launch.
    static func fetchOrCreate(in context: ModelContext) -> UserPreferencesRecord {
        if let existing = try? context.fetch(FetchDescriptor<UserPreferencesRecord>()).first {
            return existing
        }
        let record = UserPreferencesRecord()
        context.insert(record)
        return record
    }
}
