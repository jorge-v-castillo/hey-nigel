import Foundation
import SwiftData

/// `@Model` records live in the app target, not `HeyNigelCore` — this keeps
/// Core free of any persistence-framework import. This app is single-user/
/// single-device, so there's exactly one `UserPreferencesRecord`: callers
/// fetch the first one and create it if missing, rather than modeling
/// multiple profiles.
///
/// Course/tee/hole-count are NOT stored here — onboarding no longer collects
/// them. They're asked fresh at the start of every round instead (see
/// `RoundSetupCoordinator`), since the course you're playing changes far more
/// often than your name or your clubs do.
@Model
final class ClubYardageRecord {
    var name: String
    var averageCarryYards: Double
    var order: Int

    init(name: String, averageCarryYards: Double, order: Int) {
        self.name = name
        self.averageCarryYards = averageCarryYards
        self.order = order
    }
}

@Model
final class UserPreferencesRecord {
    var onboardingCompleted: Bool
    var fullName: String?
    var nickname: String?
    var email: String?

    @Relationship(deleteRule: .cascade)
    var clubYardages: [ClubYardageRecord]

    init(
        onboardingCompleted: Bool = false,
        fullName: String? = nil,
        nickname: String? = nil,
        email: String? = nil,
        clubYardages: [ClubYardageRecord] = []
    ) {
        self.onboardingCompleted = onboardingCompleted
        self.fullName = fullName
        self.nickname = nickname
        self.email = email
        self.clubYardages = clubYardages
    }
}
