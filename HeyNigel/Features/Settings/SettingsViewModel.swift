import Foundation
import SwiftData
import HeyNigelCore

@MainActor
@Observable
final class SettingsViewModel {
    var fullName: String = ""
    var nickname: String = ""
    var email: String = ""
    var clubs: [ClubYardage] = []

    private var record: UserPreferencesRecord?

    func load(from context: ModelContext) {
        let record = UserPreferencesStore.fetchOrCreate(in: context)
        self.record = record
        fullName = record.fullName ?? ""
        nickname = record.nickname ?? ""
        email = record.email ?? ""
        clubs = record.clubProfile.clubs
    }

    func save(in context: ModelContext) {
        guard let record else { return }
        record.fullName = fullName.isEmpty ? nil : fullName
        record.nickname = nickname.isEmpty ? nil : nickname
        record.email = email.isEmpty ? nil : email
        record.replaceClubProfile(PlayerClubProfile(clubs: clubs), in: context)
        try? context.save()
    }
}
