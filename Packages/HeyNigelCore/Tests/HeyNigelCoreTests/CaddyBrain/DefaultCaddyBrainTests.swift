import Testing
@testable import HeyNigelCore

@Suite("DefaultCaddyBrain")
struct DefaultCaddyBrainTests {
    // Player 150 yards due south of the green (hitting due north, bearing 0).
    let player = Coordinate(latitude: 33.50000, longitude: -111.90000)
    let green = GreenCoordinates(
        front: Coordinate(latitude: 33.50110, longitude: -111.90000),
        center: Coordinate(latitude: 33.50123, longitude: -111.90000),
        back: Coordinate(latitude: 33.50136, longitude: -111.90000)
    )
    let profile = PlayerClubProfile(clubs: [
        ClubYardage(name: "Driver", averageCarryYards: 230, order: 0),
        ClubYardage(name: "7 Iron", averageCarryYards: 150, order: 7),
        ClubYardage(name: "Sand Wedge", averageCarryYards: 80, order: 12),
    ])

    @Test("calm wind: effective yardage equals raw distance and recommends the anchor club")
    func calmWind() {
        let brain = DefaultCaddyBrain()
        let result = brain.recommendation(
            playerLocation: player, green: green, target: .center,
            wind: .calm, clubs: profile
        )
        #expect(abs(result.windAdjustedYards - result.distanceYards) < 0.01)
        #expect(result.windDescription == "calm conditions")
        #expect(result.recommendedClub == "7 Iron")
        #expect(result.isInterpolated == false)
    }

    @Test("headwind increases effective yardage beyond raw distance")
    func headwind() {
        let brain = DefaultCaddyBrain()
        // Wind FROM the north (0 degrees) blowing toward south, directly
        // opposing a shot hit due north — pure headwind.
        let wind = WindObservation(speedMph: 10, directionFromDegrees: 0)
        let result = brain.recommendation(
            playerLocation: player, green: green, target: .center,
            wind: wind, clubs: profile
        )
        #expect(result.windAdjustedYards > result.distanceYards)
        #expect(result.windDescription.contains("headwind"))
        #expect(result.adjustmentNote == "move up a club")
    }

    @Test("tailwind decreases effective yardage below raw distance")
    func tailwind() {
        let brain = DefaultCaddyBrain()
        // Wind FROM the south (180 degrees) blowing toward north, with the shot — pure tailwind.
        let wind = WindObservation(speedMph: 10, directionFromDegrees: 180)
        let result = brain.recommendation(
            playerLocation: player, green: green, target: .center,
            wind: wind, clubs: profile
        )
        #expect(result.windAdjustedYards < result.distanceYards)
        #expect(result.windDescription.contains("tailwind"))
        #expect(result.adjustmentNote == "take a bit less club")
    }

    @Test("headwind costs roughly twice what an equal tailwind gives back")
    func headwindTailwindAsymmetry() {
        let brain = DefaultCaddyBrain()
        let headwind = WindObservation(speedMph: 10, directionFromDegrees: 0)
        let tailwind = WindObservation(speedMph: 10, directionFromDegrees: 180)

        let headResult = brain.recommendation(playerLocation: player, green: green, target: .center, wind: headwind, clubs: profile)
        let tailResult = brain.recommendation(playerLocation: player, green: green, target: .center, wind: tailwind, clubs: profile)

        let headDelta = headResult.windAdjustedYards - headResult.distanceYards
        let tailDelta = tailResult.distanceYards - tailResult.windAdjustedYards
        #expect(headDelta > tailDelta)
    }

    @Test("pure crosswind leaves effective yardage close to raw distance and describes crosswind")
    func crosswind() {
        let brain = DefaultCaddyBrain()
        // Wind FROM the east (90 degrees), perpendicular to a shot hit due north.
        let wind = WindObservation(speedMph: 10, directionFromDegrees: 90)
        let result = brain.recommendation(
            playerLocation: player, green: green, target: .center,
            wind: wind, clubs: profile
        )
        #expect(abs(result.windAdjustedYards - result.distanceYards) < 0.5)
        #expect(result.windDescription.contains("crosswind"))
    }

    @Test("target defaults can be front or back of the green, not just center")
    func frontAndBackTargets() {
        let brain = DefaultCaddyBrain()
        let centerResult = brain.recommendation(playerLocation: player, green: green, target: .center, wind: .calm, clubs: profile)
        let frontResult = brain.recommendation(playerLocation: player, green: green, target: .front, wind: .calm, clubs: profile)
        let backResult = brain.recommendation(playerLocation: player, green: green, target: .back, wind: .calm, clubs: profile)

        #expect(frontResult.distanceYards < centerResult.distanceYards)
        #expect(backResult.distanceYards > centerResult.distanceYards)
    }
}
