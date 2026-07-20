import Foundation

/// Distance and bearing math between two coordinates. Core Location doesn't
/// expose bearing, and Core can't import CoreLocation anyway (it stays
/// Foundation-only so it's testable without a simulator), so this is hand-rolled.
public enum Geodesy {
    /// Mean Earth radius in yards.
    private static let earthRadiusYards = 6_371_000.0 / 0.9144

    /// Great-circle distance between two coordinates, in yards.
    public static func distanceYards(_ a: Coordinate, _ b: Coordinate) -> Double {
        let lat1 = a.latitude.radians
        let lat2 = b.latitude.radians
        let deltaLat = (b.latitude - a.latitude).radians
        let deltaLon = (b.longitude - a.longitude).radians

        let sinDeltaLat = sin(deltaLat / 2)
        let sinDeltaLon = sin(deltaLon / 2)

        let h = sinDeltaLat * sinDeltaLat
            + cos(lat1) * cos(lat2) * sinDeltaLon * sinDeltaLon
        let centralAngle = 2 * asin(min(1, sqrt(h)))
        return earthRadiusYards * centralAngle
    }

    /// Initial forward bearing from `a` to `b`, in degrees clockwise from true north, 0..<360.
    public static func bearingDegrees(from a: Coordinate, to b: Coordinate) -> Double {
        let lat1 = a.latitude.radians
        let lat2 = b.latitude.radians
        let deltaLon = (b.longitude - a.longitude).radians

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let bearing = atan2(y, x).degrees
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Signed angular difference `a - b`, normalized to (-180, 180]. Useful for
    /// comparing a bearing to a wind direction.
    public static func normalizedAngleDifference(_ a: Double, _ b: Double) -> Double {
        var diff = (a - b).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff <= -180 { diff += 360 }
        return diff
    }
}

extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
