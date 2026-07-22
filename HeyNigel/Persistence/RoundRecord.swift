import Foundation
import SwiftData
import HeyNigelCore

/// One row per hole played — the latest club/distance recommendation shown
/// while that hole was current, plus whether GPS hole-detection was
/// confirmed or corrected by voice. Not a full transcript of every question
/// asked on the hole.
@Model
final class HoleRecord {
    var holeNumber: Int
    var enteredAt: Date
    var transitionWasConfirmedByVoice: Bool
    var distanceAskedYards: Double?
    var recommendedClub: String?
    var windDescription: String?
    var wasInterpolatedClubPick: Bool

    init(
        holeNumber: Int,
        enteredAt: Date,
        transitionWasConfirmedByVoice: Bool,
        distanceAskedYards: Double? = nil,
        recommendedClub: String? = nil,
        windDescription: String? = nil,
        wasInterpolatedClubPick: Bool = false
    ) {
        self.holeNumber = holeNumber
        self.enteredAt = enteredAt
        self.transitionWasConfirmedByVoice = transitionWasConfirmedByVoice
        self.distanceAskedYards = distanceAskedYards
        self.recommendedClub = recommendedClub
        self.windDescription = windDescription
        self.wasInterpolatedClubPick = wasInterpolatedClubPick
    }
}

@Model
final class RoundRecord {
    var courseName: String
    var courseID: String
    var teeName: String
    var holeCount: Int
    var startingNineRaw: String
    var startedAt: Date
    var endedAt: Date?

    @Relationship(deleteRule: .cascade)
    var holes: [HoleRecord]

    init(
        courseName: String,
        courseID: String,
        teeName: String,
        holeCount: Int,
        startingNineRaw: String,
        startedAt: Date,
        endedAt: Date? = nil,
        holes: [HoleRecord] = []
    ) {
        self.courseName = courseName
        self.courseID = courseID
        self.teeName = teeName
        self.holeCount = holeCount
        self.startingNineRaw = startingNineRaw
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.holes = holes
    }
}
