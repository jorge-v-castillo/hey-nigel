import Foundation
import HeyNigelCore
import HeyNigelWeather

/// Owns the active `Round` and recomputes `currentHoleNumber` from GPS via
/// `NearestHoleDetector` (already unit-tested in HeyNigelCore). This cached
/// state — not a fresh GPS fix requested on demand — is what the future Siri
/// and AirPods paths will read, since both need an answer faster than a new
/// location fix can arrive.
@MainActor
@Observable
final class RoundSessionManager {
    private(set) var activeRound: Round?
    private(set) var currentLocation: Coordinate?
    private(set) var recommendation: ClubRecommendation?
    private(set) var spokenPhrase: String?
    private(set) var isRefreshing = false

    private var holeDetector: NearestHoleDetector?
    private var clubProfile = PlayerClubProfile(clubs: [])

    private let caddyBrain: CaddyBrain
    private let weatherProvider: WeatherProvider
    private let responsePhraser: ResponsePhraser
    private let locationManager: LocationManager

    init(
        caddyBrain: CaddyBrain,
        weatherProvider: WeatherProvider,
        responsePhraser: ResponsePhraser,
        locationManager: LocationManager
    ) {
        self.caddyBrain = caddyBrain
        self.weatherProvider = weatherProvider
        self.responsePhraser = responsePhraser
        self.locationManager = locationManager
        self.locationManager.onLocationUpdate = { [weak self] coordinate in
            self?.handleLocationUpdate(coordinate)
        }
    }

    func startRound(course: Course, tee: String, holeCount: Int, startingNine: Nine, clubProfile: PlayerClubProfile) {
        let startingHoleNumber = startingNine == .back ? 10 : 1
        self.clubProfile = clubProfile
        activeRound = Round(
            courseSnapshot: course,
            selectedTee: tee,
            holeCount: holeCount,
            startingNine: startingNine,
            currentHoleNumber: startingHoleNumber
        )
        holeDetector = NearestHoleDetector(holes: course.holes, startingHoleNumber: startingHoleNumber)
        locationManager.startUpdating()
    }

    func endRound() {
        locationManager.stopUpdating()
        activeRound = nil
        holeDetector = nil
        currentLocation = nil
        recommendation = nil
        spokenPhrase = nil
    }

    private func handleLocationUpdate(_ coordinate: Coordinate) {
        currentLocation = coordinate
        guard activeRound != nil else { return }
        if let updatedHoleNumber = holeDetector?.update(location: coordinate) {
            activeRound?.currentHoleNumber = updatedHoleNumber
        }
        Task { await refreshRecommendation() }
    }

    func refreshRecommendation() async {
        guard let round = activeRound, let hole = round.currentHole, let location = currentLocation else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let wind = try await weatherProvider.currentWind(at: hole.green.center)
            let result = caddyBrain.recommendation(
                playerLocation: location,
                green: hole.green,
                target: .center,
                wind: wind,
                clubs: clubProfile
            )
            recommendation = result
            spokenPhrase = responsePhraser.phrase(hole: hole.number, target: .center, recommendation: result)
        } catch {
            spokenPhrase = "Couldn't get wind data right now."
        }
    }
}
