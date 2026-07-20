import Foundation

public protocol HoleDetector {
    /// Feed a new player location and get back the hole number Nigel currently
    /// believes the player is on. Callers should treat an explicit spoken/typed
    /// hole number as an override that always wins over this for that query.
    mutating func update(location: Coordinate) -> Int
}
