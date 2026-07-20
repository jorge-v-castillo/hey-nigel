import Foundation

/// Determines the current hole by nearest green-center, with hysteresis so the
/// "current hole" doesn't flicker on courses with parallel/adjacent fairways:
/// a new candidate must be closer by `switchMarginYards` *and* stay the
/// closest candidate for `requiredConsecutiveUpdates` in a row before Nigel
/// switches to it.
public struct NearestHoleDetector: HoleDetector {
    private let holes: [Hole]
    private let switchMarginYards: Double
    private let requiredConsecutiveUpdates: Int

    private var currentHoleNumber: Int
    private var pendingCandidate: Int?
    private var pendingStreak: Int = 0

    public init(
        holes: [Hole],
        startingHoleNumber: Int,
        switchMarginYards: Double = 45,
        requiredConsecutiveUpdates: Int = 3
    ) {
        precondition(!holes.isEmpty, "NearestHoleDetector requires at least one hole")
        self.holes = holes
        self.switchMarginYards = switchMarginYards
        self.requiredConsecutiveUpdates = requiredConsecutiveUpdates
        self.currentHoleNumber = startingHoleNumber
    }

    public var current: Int { currentHoleNumber }

    @discardableResult
    public mutating func update(location: Coordinate) -> Int {
        let distances = holes.map { hole in
            (number: hole.number, distance: Geodesy.distanceYards(location, hole.green.center))
        }
        guard let nearest = distances.min(by: { $0.distance < $1.distance }) else {
            return currentHoleNumber
        }

        if nearest.number == currentHoleNumber {
            pendingCandidate = nil
            pendingStreak = 0
            return currentHoleNumber
        }

        let currentDistance = distances.first { $0.number == currentHoleNumber }?.distance ?? .infinity
        let isCloserByMargin = currentDistance - nearest.distance >= switchMarginYards

        guard isCloserByMargin else {
            pendingCandidate = nil
            pendingStreak = 0
            return currentHoleNumber
        }

        if pendingCandidate == nearest.number {
            pendingStreak += 1
        } else {
            pendingCandidate = nearest.number
            pendingStreak = 1
        }

        if pendingStreak >= requiredConsecutiveUpdates {
            currentHoleNumber = nearest.number
            pendingCandidate = nil
            pendingStreak = 0
        }

        return currentHoleNumber
    }
}
