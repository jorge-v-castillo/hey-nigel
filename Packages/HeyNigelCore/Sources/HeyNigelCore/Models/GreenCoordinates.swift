import Foundation

/// The three points on a green that "distance to the hole" can be measured to.
/// Real-time pin position isn't available from course data providers (it moves
/// daily), so Nigel measures to these fixed points instead. Default target is `.center`.
public struct GreenCoordinates: Codable, Hashable, Sendable {
    public var front: Coordinate
    public var center: Coordinate
    public var back: Coordinate

    public init(front: Coordinate, center: Coordinate, back: Coordinate) {
        self.front = front
        self.center = center
        self.back = back
    }

    public func coordinate(for target: GreenTarget) -> Coordinate {
        switch target {
        case .front: return front
        case .center: return center
        case .back: return back
        }
    }
}

public enum GreenTarget: String, Codable, Sendable {
    case front, center, back
}
