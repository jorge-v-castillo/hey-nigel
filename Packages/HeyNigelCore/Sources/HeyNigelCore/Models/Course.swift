import Foundation

public struct TeeSet: Codable, Hashable, Sendable {
    public var name: String
    public var rating: Double?
    public var slope: Int?
    public var totalYardage: Int?

    public init(name: String, rating: Double? = nil, slope: Int? = nil, totalYardage: Int? = nil) {
        self.name = name
        self.rating = rating
        self.slope = slope
        self.totalYardage = totalYardage
    }
}

public struct Course: Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var location: String
    public var teeSets: [TeeSet]
    public var holes: [Hole]
    /// The identifier used by whichever CourseDataProvider vendor supplied this course.
    public var externalID: String?

    public init(
        id: String,
        name: String,
        location: String,
        teeSets: [TeeSet],
        holes: [Hole],
        externalID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.teeSets = teeSets
        self.holes = holes
        self.externalID = externalID
    }

    public func hole(number: Int) -> Hole? {
        holes.first { $0.number == number }
    }
}

public struct CourseSummary: Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var location: String

    public init(id: String, name: String, location: String) {
        self.id = id
        self.name = name
        self.location = location
    }
}
