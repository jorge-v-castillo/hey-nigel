import Foundation

public enum Nine: String, Codable, Sendable {
    case front, back
}

/// A snapshot of the course at the moment the round started, not a live
/// reference — so a past round stays stable even if a vendor's course data
/// changes later.
public struct Round: Codable, Hashable, Sendable {
    public var courseSnapshot: Course
    public var selectedTee: String
    public var holeCount: Int
    public var startingNine: Nine?
    public var currentHoleNumber: Int
    public var isActive: Bool
    public var startedAt: Date

    public init(
        courseSnapshot: Course,
        selectedTee: String,
        holeCount: Int,
        startingNine: Nine? = nil,
        currentHoleNumber: Int,
        isActive: Bool = true,
        startedAt: Date = Date()
    ) {
        self.courseSnapshot = courseSnapshot
        self.selectedTee = selectedTee
        self.holeCount = holeCount
        self.startingNine = startingNine
        self.currentHoleNumber = currentHoleNumber
        self.isActive = isActive
        self.startedAt = startedAt
    }

    public var currentHole: Hole? {
        courseSnapshot.hole(number: currentHoleNumber)
    }
}
