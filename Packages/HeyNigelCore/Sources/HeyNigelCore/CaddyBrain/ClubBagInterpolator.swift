import Foundation

/// Onboarding only requires driver/7-iron/wedge yardages (asking for all 14
/// clubs up front is too much friction). This synthesizes a full virtual bag
/// from whichever clubs the player *did* provide, using `PlayerClubProfile
/// .standardOrder` as the slot template and linear interpolation/extrapolation
/// between known anchors to fill the gaps.
public struct ClubBagInterpolator: Sendable {
    /// Yardage drop assumed per slot when only one club is known (no second
    /// anchor to compute a real gap from).
    private let fallbackGapYards: Double

    public init(fallbackGapYards: Double = 10) {
        self.fallbackGapYards = fallbackGapYards
    }

    public func synthesizedBag(from profile: PlayerClubProfile) -> [ClubYardage] {
        let slots = PlayerClubProfile.standardOrder
        var knownBySlot: [Int: Double] = [:]
        for club in profile.clubs {
            if let idx = slots.firstIndex(where: { $0.caseInsensitiveCompare(club.name) == .orderedSame }) {
                knownBySlot[idx] = club.averageCarryYards
            }
        }
        guard !knownBySlot.isEmpty else { return profile.clubs }

        let knownIndices = knownBySlot.keys.sorted()
        return slots.enumerated().map { index, name in
            let yardage = knownBySlot[index]
                ?? interpolatedYardage(forSlot: index, knownIndices: knownIndices, knownBySlot: knownBySlot)
            return ClubYardage(name: name, averageCarryYards: yardage, order: index)
        }
    }

    /// Picks the club whose synthesized bag yardage is closest to `yards`.
    /// `isInterpolated` is true when the pick wasn't one of the player's
    /// actually-known clubs — callers should hedge the spoken response then.
    public func recommendClub(forEffectiveYards yards: Double, profile: PlayerClubProfile) -> (club: ClubYardage, isInterpolated: Bool) {
        let bag = synthesizedBag(from: profile)
        let knownNames = Set(profile.clubs.map { $0.name.lowercased() })
        guard let nearest = bag.min(by: { abs($0.averageCarryYards - yards) < abs($1.averageCarryYards - yards) }) else {
            let fallback = ClubYardage(name: "your longest club", averageCarryYards: yards, order: 0)
            return (fallback, true)
        }
        let isInterpolated = !knownNames.contains(nearest.name.lowercased())
        return (nearest, isInterpolated)
    }

    private func interpolatedYardage(forSlot slot: Int, knownIndices: [Int], knownBySlot: [Int: Double]) -> Double {
        if knownIndices.count == 1 {
            let onlyIndex = knownIndices[0]
            let onlyYardage = knownBySlot[onlyIndex]!
            return onlyYardage - Double(slot - onlyIndex) * fallbackGapYards
        }

        if let lower = knownIndices.last(where: { $0 < slot }), let upper = knownIndices.first(where: { $0 > slot }) {
            let lowerYardage = knownBySlot[lower]!
            let upperYardage = knownBySlot[upper]!
            let fraction = Double(slot - lower) / Double(upper - lower)
            return lowerYardage + (upperYardage - lowerYardage) * fraction
        }

        if slot < knownIndices.first! {
            let first = knownIndices[0]
            let second = knownIndices[1]
            let gapPerSlot = (knownBySlot[first]! - knownBySlot[second]!) / Double(second - first)
            return knownBySlot[first]! + Double(first - slot) * gapPerSlot
        }

        let last = knownIndices[knownIndices.count - 1]
        let secondLast = knownIndices[knownIndices.count - 2]
        let gapPerSlot = (knownBySlot[secondLast]! - knownBySlot[last]!) / Double(last - secondLast)
        return knownBySlot[last]! - Double(slot - last) * gapPerSlot
    }
}
