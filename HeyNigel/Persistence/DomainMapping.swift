import Foundation
import SwiftData
import HeyNigelCore

/// Explicit mapping between SwiftData `@Model` records and `HeyNigelCore`'s
/// plain Codable structs — keeps Core dependency-free while still letting the
/// rest of the app work in terms of its clean domain types.
extension UserPreferencesRecord {
    /// What Nigel calls the player out loud — the nickname if they gave one,
    /// otherwise their first name.
    var displayName: String? {
        if let nickname, !nickname.isEmpty { return nickname }
        guard let fullName, !fullName.isEmpty else { return nil }
        return fullName.split(separator: " ").first.map(String.init) ?? fullName
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
