import Testing
@testable import HeyNigelCore

@Suite("Geodesy")
struct GeodesyTests {
    // 1 degree of latitude is ~60.7 nautical miles ~= 121,000 yards.
    @Test("distance north-south over 1 degree latitude is ~121,000 yards")
    func distanceOneDegreeLatitude() {
        let a = Coordinate(latitude: 0, longitude: 0)
        let b = Coordinate(latitude: 1, longitude: 0)
        let distance = Geodesy.distanceYards(a, b)
        #expect(abs(distance - 121_269) < 500)
    }

    @Test("distance to self is zero")
    func distanceToSelf() {
        let a = Coordinate(latitude: 33.5, longitude: -111.9)
        #expect(Geodesy.distanceYards(a, a) == 0)
    }

    @Test("known short distance: ~100 yards north")
    func knownShortDistance() {
        // ~100 yards north-south is about 0.000823 degrees of latitude.
        let a = Coordinate(latitude: 33.50000, longitude: -111.90000)
        let b = Coordinate(latitude: 33.50082, longitude: -111.90000)
        let distance = Geodesy.distanceYards(a, b)
        #expect(abs(distance - 100) < 5)
    }

    @Test("bearing due north is 0 degrees")
    func bearingDueNorth() {
        let a = Coordinate(latitude: 33.5, longitude: -111.9)
        let b = Coordinate(latitude: 33.6, longitude: -111.9)
        let bearing = Geodesy.bearingDegrees(from: a, to: b)
        #expect(abs(bearing - 0) < 0.5)
    }

    @Test("bearing due east is 90 degrees")
    func bearingDueEast() {
        let a = Coordinate(latitude: 33.5, longitude: -111.9)
        let b = Coordinate(latitude: 33.5, longitude: -111.8)
        let bearing = Geodesy.bearingDegrees(from: a, to: b)
        #expect(abs(bearing - 90) < 0.5)
    }

    @Test("bearing due south is 180 degrees")
    func bearingDueSouth() {
        let a = Coordinate(latitude: 33.5, longitude: -111.9)
        let b = Coordinate(latitude: 33.4, longitude: -111.9)
        let bearing = Geodesy.bearingDegrees(from: a, to: b)
        #expect(abs(bearing - 180) < 0.5)
    }

    @Test("bearing due west is 270 degrees")
    func bearingDueWest() {
        let a = Coordinate(latitude: 33.5, longitude: -111.9)
        let b = Coordinate(latitude: 33.5, longitude: -112.0)
        let bearing = Geodesy.bearingDegrees(from: a, to: b)
        #expect(abs(bearing - 270) < 0.5)
    }

    @Test("normalized angle difference wraps correctly", arguments: [
        (10.0, 350.0, 20.0),
        (350.0, 10.0, -20.0),
        (0.0, 180.0, 180.0),
        (190.0, 0.0, -170.0),
    ])
    func normalizedAngleDifference(a: Double, b: Double, expected: Double) {
        let diff = Geodesy.normalizedAngleDifference(a, b)
        #expect(abs(diff - expected) < 0.5)
    }
}
