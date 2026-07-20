import Testing
import HeyNigelCore
@testable import HeyNigelWeather

@Suite("MockWeatherProvider")
struct MockWeatherProviderTests {
    @Test("returns the configured observation regardless of coordinate")
    func returnsConfiguredObservation() async throws {
        let wind = WindObservation(speedMph: 12, directionFromDegrees: 270)
        let provider = MockWeatherProvider(observation: wind)
        let result = try await provider.currentWind(at: Coordinate(latitude: 0, longitude: 0))
        #expect(result.speedMph == 12)
        #expect(result.directionFromDegrees == 270)
    }

    @Test("defaults to calm when no observation is configured")
    func defaultsToCalm() async throws {
        let provider = MockWeatherProvider()
        let result = try await provider.currentWind(at: Coordinate(latitude: 0, longitude: 0))
        #expect(result.speedMph == 0)
    }
}
