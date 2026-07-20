import Foundation

public struct Hole: Codable, Hashable, Sendable {
    public var number: Int
    public var par: Int
    public var handicapIndex: Int?
    public var teeBoxes: [TeeBox]
    public var green: GreenCoordinates
    /// Yardage from each tee name to the green center.
    public var yardageByTee: [String: Int]

    public init(
        number: Int,
        par: Int,
        handicapIndex: Int? = nil,
        teeBoxes: [TeeBox],
        green: GreenCoordinates,
        yardageByTee: [String: Int]
    ) {
        self.number = number
        self.par = par
        self.handicapIndex = handicapIndex
        self.teeBoxes = teeBoxes
        self.green = green
        self.yardageByTee = yardageByTee
    }
}
