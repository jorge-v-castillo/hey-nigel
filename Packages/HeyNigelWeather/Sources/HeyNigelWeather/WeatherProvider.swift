import Foundation
import HeyNigelCore

/// Abstracts wind data behind a protocol so `CaddyBrain` never depends on a
/// specific weather vendor. The real implementation (`WeatherKitProvider`,
/// app-target only — WeatherKit requires a paid Apple Developer entitlement
/// and can't live in a plain SPM package) is Phase 4 work; `MockWeatherProvider`
/// unblocks everything before that.
public protocol WeatherProvider: Sendable {
    func currentWind(at coordinate: Coordinate) async throws -> WindObservation
}
