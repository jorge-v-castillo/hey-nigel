import Foundation
import HeyNigelCore

/// Returns a fixed or scripted sequence of wind observations — useful for
/// previews, unit tests, and developing the CaddyBrain/UI path before
/// WeatherKit is wired up.
public struct MockWeatherProvider: WeatherProvider {
    private let observation: WindObservation

    public init(observation: WindObservation = .calm) {
        self.observation = observation
    }

    public func currentWind(at coordinate: Coordinate) async throws -> WindObservation {
        observation
    }
}
