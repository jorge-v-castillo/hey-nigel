import Foundation

/// `directionFromDegrees` uses the meteorological "from" convention (e.g. 0/360
/// = wind blowing from the north, toward the south) — the same convention
/// weather services report in, so no conversion is needed at ingestion time.
public struct WindObservation: Codable, Hashable, Sendable {
    public var speedMph: Double
    public var directionFromDegrees: Double
    public var gustMph: Double?
    public var observedAt: Date

    public init(speedMph: Double, directionFromDegrees: Double, gustMph: Double? = nil, observedAt: Date = Date()) {
        self.speedMph = speedMph
        self.directionFromDegrees = directionFromDegrees
        self.gustMph = gustMph
        self.observedAt = observedAt
    }

    public static let calm = WindObservation(speedMph: 0, directionFromDegrees: 0)
}
