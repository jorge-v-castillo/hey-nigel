import Foundation

/// A plain, persistence-framework-free snapshot of one hole's activity during
/// a round. `RoundSessionManager` hands these out via an `onRoundEvent`
/// closure rather than importing SwiftData itself, keeping it as
/// framework-light as the rest of the app's non-UI layer.
public struct HoleRecordSnapshot: Codable, Hashable, Sendable {
    public var holeNumber: Int
    public var enteredAt: Date
    public var transitionWasConfirmedByVoice: Bool
    public var distanceAskedYards: Double?
    public var recommendedClub: String?
    public var windDescription: String?
    public var wasInterpolatedClubPick: Bool

    public init(
        holeNumber: Int,
        enteredAt: Date = Date(),
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

/// Emitted by `RoundSessionManager` for the app layer to persist (as a
/// `RoundRecord`/`HoleRecord` in SwiftData) without the session manager
/// itself depending on a persistence framework.
public enum RoundEvent: Sendable {
    case roundStarted(course: Course, tee: String, holeCount: Int, startingNine: Nine)
    case holeRecorded(HoleRecordSnapshot)
    case roundEnded(endedAt: Date)
}
