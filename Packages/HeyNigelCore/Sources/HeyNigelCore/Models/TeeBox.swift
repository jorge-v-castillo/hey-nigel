import Foundation

public struct TeeBox: Codable, Hashable, Sendable {
    public var name: String
    public var colorHex: String?
    public var coordinate: Coordinate

    public init(name: String, colorHex: String? = nil, coordinate: Coordinate) {
        self.name = name
        self.colorHex = colorHex
        self.coordinate = coordinate
    }
}
