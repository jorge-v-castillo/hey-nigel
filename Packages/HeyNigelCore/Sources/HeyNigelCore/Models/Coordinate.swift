import Foundation

/// A plain, Codable lat/long pair. `CLLocationCoordinate2D` isn't Codable or
/// Hashable, so Core defines its own type; the OS layer converts at the boundary.
public struct Coordinate: Codable, Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
