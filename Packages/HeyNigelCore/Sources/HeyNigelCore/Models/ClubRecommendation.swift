import Foundation

public struct ClubRecommendation: Codable, Hashable, Sendable {
    public var distanceYards: Double
    public var windAdjustedYards: Double
    public var recommendedClub: String
    /// e.g. "steady 10 mph headwind" — describes the wind in caddy language.
    public var windDescription: String
    /// e.g. "move up a club" — describes what changed vs. the raw-distance club.
    public var adjustmentNote: String
    /// True when `recommendedClub` came from interpolation rather than one of
    /// the player's known anchor clubs (driver/7-iron/wedge) — spoken responses
    /// should hedge slightly when this is true.
    public var isInterpolated: Bool

    public init(
        distanceYards: Double,
        windAdjustedYards: Double,
        recommendedClub: String,
        windDescription: String,
        adjustmentNote: String,
        isInterpolated: Bool
    ) {
        self.distanceYards = distanceYards
        self.windAdjustedYards = windAdjustedYards
        self.recommendedClub = recommendedClub
        self.windDescription = windDescription
        self.adjustmentNote = adjustmentNote
        self.isInterpolated = isInterpolated
    }
}
