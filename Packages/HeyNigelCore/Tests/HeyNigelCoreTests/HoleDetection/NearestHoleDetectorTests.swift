import Testing
@testable import HeyNigelCore

@Suite("NearestHoleDetector")
struct NearestHoleDetectorTests {
    /// Builds a hole whose green center sits `offsetDegrees` of latitude away
    /// from the equator, spaced far enough apart (~0.01 deg ~= 1,200 yards)
    /// that holes are unambiguous.
    private func makeHole(number: Int, latOffset: Double) -> Hole {
        let green = GreenCoordinates(
            front: Coordinate(latitude: latOffset - 0.0001, longitude: 0),
            center: Coordinate(latitude: latOffset, longitude: 0),
            back: Coordinate(latitude: latOffset + 0.0001, longitude: 0)
        )
        return Hole(
            number: number,
            par: 4,
            teeBoxes: [TeeBox(name: "White", coordinate: Coordinate(latitude: latOffset - 0.003, longitude: 0))],
            green: green,
            yardageByTee: ["White": 380]
        )
    }

    @Test("stays on current hole when player hasn't moved closer to another hole")
    func staysOnCurrentHole() {
        let holes = [makeHole(number: 1, latOffset: 0.00), makeHole(number: 2, latOffset: 0.01)]
        var detector = NearestHoleDetector(holes: holes, startingHoleNumber: 1)
        let nearHole1 = Coordinate(latitude: 0.0005, longitude: 0)
        #expect(detector.update(location: nearHole1) == 1)
        #expect(detector.update(location: nearHole1) == 1)
    }

    @Test("switches hole after required consecutive updates near the new hole")
    func switchesAfterConsecutiveUpdates() {
        let holes = [makeHole(number: 1, latOffset: 0.00), makeHole(number: 2, latOffset: 0.01)]
        var detector = NearestHoleDetector(
            holes: holes,
            startingHoleNumber: 1,
            switchMarginYards: 45,
            requiredConsecutiveUpdates: 3
        )
        let nearHole2 = Coordinate(latitude: 0.0098, longitude: 0)

        #expect(detector.update(location: nearHole2) == 1) // 1st streak update
        #expect(detector.update(location: nearHole2) == 1) // 2nd streak update
        #expect(detector.update(location: nearHole2) == 2) // 3rd — switches
    }

    @Test("streak resets if player wobbles back toward the old hole mid-transition")
    func streakResetsOnWobble() {
        let holes = [makeHole(number: 1, latOffset: 0.00), makeHole(number: 2, latOffset: 0.01)]
        var detector = NearestHoleDetector(
            holes: holes,
            startingHoleNumber: 1,
            switchMarginYards: 45,
            requiredConsecutiveUpdates: 3
        )
        let nearHole2 = Coordinate(latitude: 0.0098, longitude: 0)
        let nearHole1 = Coordinate(latitude: 0.0005, longitude: 0)

        #expect(detector.update(location: nearHole2) == 1) // streak 1
        #expect(detector.update(location: nearHole2) == 1) // streak 2
        #expect(detector.update(location: nearHole1) == 1) // wobble back — resets streak
        #expect(detector.update(location: nearHole2) == 1) // streak 1 again
        #expect(detector.update(location: nearHole2) == 1) // streak 2
        #expect(detector.update(location: nearHole2) == 2) // streak 3 — switches
    }

    @Test("does not switch when new candidate is closer but not beyond the margin")
    func doesNotSwitchWithinMargin() {
        // Two holes whose greens are only ~20 yards apart in the "nearest"
        // sense won't clear a 45-yard margin, so the detector should hold.
        let holes = [makeHole(number: 1, latOffset: 0.00), makeHole(number: 2, latOffset: 0.0002)]
        var detector = NearestHoleDetector(
            holes: holes,
            startingHoleNumber: 1,
            switchMarginYards: 45,
            requiredConsecutiveUpdates: 1
        )
        let midpoint = Coordinate(latitude: 0.0001, longitude: 0)
        #expect(detector.update(location: midpoint) == 1)
        #expect(detector.update(location: midpoint) == 1)
    }

    @Test("overrideCurrentHole jumps directly to the given hole")
    func overrideJumpsToHole() {
        let holes = [makeHole(number: 1, latOffset: 0.00), makeHole(number: 2, latOffset: 0.01)]
        var detector = NearestHoleDetector(holes: holes, startingHoleNumber: 1)
        detector.overrideCurrentHole(2)
        #expect(detector.current == 2)
    }

    @Test("overrideCurrentHole clears a pending in-progress streak")
    func overrideClearsPendingStreak() {
        let holes = [makeHole(number: 1, latOffset: 0.00), makeHole(number: 2, latOffset: 0.01)]
        var detector = NearestHoleDetector(
            holes: holes,
            startingHoleNumber: 1,
            switchMarginYards: 45,
            requiredConsecutiveUpdates: 3
        )
        let nearHole2 = Coordinate(latitude: 0.0098, longitude: 0)
        #expect(detector.update(location: nearHole2) == 1) // streak 1
        #expect(detector.update(location: nearHole2) == 1) // streak 2

        detector.overrideCurrentHole(1) // reject the pending switch, roll back

        // Streak should have reset — two more updates near hole 2 shouldn't
        // be enough to switch (needs 3 in a row from a clean slate).
        #expect(detector.update(location: nearHole2) == 1)
        #expect(detector.update(location: nearHole2) == 1)
        #expect(detector.update(location: nearHole2) == 2) // 3rd since override — switches
    }
}
