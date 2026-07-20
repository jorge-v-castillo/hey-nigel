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

/// The player's known carry yardages. Onboarding requires at minimum
/// driver/7-iron/wedge; more clubs can be added later in Settings for
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
}
