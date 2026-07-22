import Foundation

public struct ClubYardage: Codable, Hashable, Sendable {
    public var name: String
    public var averageCarryYards: Double
    /// Lower order = hit farther (e.g. Driver = 0). Used to sort the bag and
    /// to interpolate synthetic clubs between known anchors.
    public var order: Int

    public init(name: String, averageCarryYards: Double, order: Int) {
        self.name = name
        self.averageCarryYards = averageCarryYards
        self.order = order
    }
}

/// The player's known carry yardages. Onboarding walks through
/// `requiredOnboardingClubs` (skippable per-club); more clubs — including
/// custom ones outside `standardOrder` — can be added later in Settings for
/// tighter club-recommendation accuracy.
public struct PlayerClubProfile: Codable, Hashable, Sendable {
    public var clubs: [ClubYardage]

    public init(clubs: [ClubYardage]) {
        self.clubs = clubs.sorted { $0.order < $1.order }
    }

    public static let standardOrder: [String] = [
        "Driver", "3 Wood", "5 Wood", "3 Hybrid", "4 Iron", "5 Iron",
        "6 Iron", "7 Iron", "8 Iron", "9 Iron", "Pitching Wedge",
        "Gap Wedge", "Sand Wedge", "Lob Wedge",
    ]

    /// The 9 clubs onboarding asks for, in the order they're asked. A subset
    /// of `standardOrder` — the skipped slots (5 Wood, 3 Hybrid, 4 Iron, Gap
    /// Wedge, Lob Wedge) are filled in by `ClubBagInterpolator` if needed.
    public static let requiredOnboardingClubs: [String] = [
        "Driver", "3 Wood", "5 Iron", "6 Iron", "7 Iron",
        "8 Iron", "9 Iron", "Pitching Wedge", "Sand Wedge",
    ]

    /// Custom clubs added beyond `requiredOnboardingClubs` sort after every
    /// template slot, keyed off their insertion order rather than any
    /// golf-specific ordering.
    public static func nextCustomClubOrder(existingCount: Int) -> Int {
        1000 + existingCount
    }
}
