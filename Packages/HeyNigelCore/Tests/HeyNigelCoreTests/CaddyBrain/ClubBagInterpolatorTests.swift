import Testing
@testable import HeyNigelCore

@Suite("ClubBagInterpolator")
struct ClubBagInterpolatorTests {
    let profile = PlayerClubProfile(clubs: [
        ClubYardage(name: "Driver", averageCarryYards: 230, order: 0),
        ClubYardage(name: "7 Iron", averageCarryYards: 150, order: 7),
        ClubYardage(name: "Sand Wedge", averageCarryYards: 80, order: 12),
    ])

    @Test("known anchor clubs keep their exact yardage in the synthesized bag")
    func anchorsPreserved() {
        let bag = ClubBagInterpolator().synthesizedBag(from: profile)
        #expect(bag.first { $0.name == "Driver" }?.averageCarryYards == 230)
        #expect(bag.first { $0.name == "7 Iron" }?.averageCarryYards == 150)
        #expect(bag.first { $0.name == "Sand Wedge" }?.averageCarryYards == 80)
    }

    @Test("interpolated club between two anchors sits between their yardages")
    func interpolatedBetweenAnchors() {
        let bag = ClubBagInterpolator().synthesizedBag(from: profile)
        let nineIron = bag.first { $0.name == "9 Iron" }!
        #expect(nineIron.averageCarryYards < 150)
        #expect(nineIron.averageCarryYards > 80)
    }

    @Test("recommendClub picks driver for a very long shot and flags it as a known club")
    func recommendsDriverForLongShot() {
        let (club, isInterpolated) = ClubBagInterpolator().recommendClub(forEffectiveYards: 235, profile: profile)
        #expect(club.name == "Driver")
        #expect(isInterpolated == false)
    }

    @Test("recommendClub picks 7 iron exactly at its known yardage")
    func recommendsSevenIronAtAnchor() {
        let (club, isInterpolated) = ClubBagInterpolator().recommendClub(forEffectiveYards: 150, profile: profile)
        #expect(club.name == "7 Iron")
        #expect(isInterpolated == false)
    }

    @Test("recommendClub between two anchors picks an interpolated club and flags it")
    func recommendsInterpolatedClubBetweenAnchors() {
        // Roughly midway between 7 Iron (150) and Sand Wedge (80).
        let (club, isInterpolated) = ClubBagInterpolator().recommendClub(forEffectiveYards: 115, profile: profile)
        #expect(club.name != "7 Iron")
        #expect(club.name != "Sand Wedge")
        #expect(isInterpolated == true)
    }

    @Test("single-anchor profile still produces a usable bag via fallback gap")
    func singleAnchorFallback() {
        let single = PlayerClubProfile(clubs: [ClubYardage(name: "7 Iron", averageCarryYards: 150, order: 7)])
        let bag = ClubBagInterpolator().synthesizedBag(from: single)
        let sixIron = bag.first { $0.name == "6 Iron" }!
        let eightIron = bag.first { $0.name == "8 Iron" }!
        #expect(sixIron.averageCarryYards > 150)
        #expect(eightIron.averageCarryYards < 150)
    }
}
