import Foundation
import SwiftData

/// `@Model` records live in the app target, not `HeyNigelCore` — this keeps
/// Core free of any persistence-framework import. This app is single-user/
/// single-device, so there's exactly one `UserPreferencesRecord`: callers
/// fetch the first one and create it if missing, rather than modeling
/// multiple profiles.
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
    var selectedCourseID: String?
    var selectedCourseName: String?
    var selectedTeeName: String?
    var holeCount: Int
    /// Raw storage for `Nine?` — SwiftData doesn't need Core's enum, so this
    /// stays a plain string and gets bridged in DomainMapping.swift.
    var startingNineRaw: String?

    @Relationship(deleteRule: .cascade)
    var clubYardages: [ClubYardageRecord]

    init(
        onboardingCompleted: Bool = false,
        selectedCourseID: String? = nil,
        selectedCourseName: String? = nil,
        selectedTeeName: String? = nil,
        holeCount: Int = 18,
        startingNineRaw: String? = nil,
        clubYardages: [ClubYardageRecord] = []
    ) {
        self.onboardingCompleted = onboardingCompleted
        self.selectedCourseID = selectedCourseID
        self.selectedCourseName = selectedCourseName
        self.selectedTeeName = selectedTeeName
        self.holeCount = holeCount
        self.startingNineRaw = startingNineRaw
        self.clubYardages = clubYardages
    }
}
