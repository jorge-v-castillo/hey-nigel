import Foundation

/// Tunable constants for wind-adjusted distance, exposed as a struct so they
/// can be recalibrated from real-round feedback without touching call sites.
/// Default reflects a common golf heuristic: headwind costs roughly twice
/// what a tailwind gives back.
public struct WindAdjustmentConstants: Sendable {
    public var headwindYardsPerMph: Double
    public var tailwindYardsPerMph: Double

    public init(headwindYardsPerMph: Double = 1.0, tailwindYardsPerMph: Double = 0.5) {
        self.headwindYardsPerMph = headwindYardsPerMph
        self.tailwindYardsPerMph = tailwindYardsPerMph
    }

    public static let standard = WindAdjustmentConstants()
}
