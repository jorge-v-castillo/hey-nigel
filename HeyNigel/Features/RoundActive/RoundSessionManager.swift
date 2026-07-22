import Foundation
import HeyNigelCore
import HeyNigelWeather

/// Owns the active `Round` and recomputes `currentHoleNumber` from GPS via
/// `NearestHoleDetector` (already unit-tested in HeyNigelCore). This cached
/// state — not a fresh GPS fix requested on demand — is what the AirPods and
/// Siri paths read, since both need an answer faster than a new location fix
/// can arrive.
///
/// Hole transitions are staged, not applied silently: when GPS suggests a new
/// hole, `pendingHoleChange` is set instead of committing directly, and the
/// owning view drives a spoken "is that correct?" confirmation before
/// `confirmPendingHoleChange` actually moves the round forward (or rolls it
/// back). `onRoundEvent` reports round/hole activity to the app layer for
/// persistence, without this type importing SwiftData itself.
@MainActor
@Observable
final class RoundSessionManager {
    private(set) var activeRound: Round?
    private(set) var currentLocation: Coordinate?
    private(set) var recommendation: ClubRecommendation?
    private(set) var spokenPhrase: String?
    private(set) var isRefreshing = false
    private(set) var pendingHoleChange: Int?

    private var holeDetector: NearestHoleDetector?
    private var clubProfile = PlayerClubProfile(clubs: [])
    private var holeChangeRollbackTarget: Int?
    private var holeConfirmedByVoice: [Int: Bool] = [:]

    private let caddyBrain: CaddyBrain
    private let weatherProvider: WeatherProvider
    private let responsePhraser: ResponsePhraser
    private let locationManager: LocationManager

    var onRoundEvent: ((RoundEvent) -> Void)?

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
        holeConfirmedByVoice = [startingHoleNumber: true]
        pendingHoleChange = nil
        holeChangeRollbackTarget = nil
        locationManager.startUpdating()
        onRoundEvent?(.roundStarted(course: course, tee: tee, holeCount: holeCount, startingNine: startingNine))
    }

    func endRound() {
        locationManager.stopUpdating()
        activeRound = nil
        holeDetector = nil
        currentLocation = nil
        recommendation = nil
        spokenPhrase = nil
        pendingHoleChange = nil
        holeChangeRollbackTarget = nil
        holeConfirmedByVoice = [:]
        onRoundEvent?(.roundEnded(endedAt: Date()))
    }

    private func handleLocationUpdate(_ coordinate: Coordinate) {
        currentLocation = coordinate
        guard let round = activeRound else { return }

        // A confirmation is already outstanding — hold off on evaluating
        // further hole changes until the player answers it.
        if pendingHoleChange == nil {
            let previousHoleNumber = round.currentHoleNumber
            if let updatedHoleNumber = holeDetector?.update(location: coordinate), updatedHoleNumber != previousHoleNumber {
                pendingHoleChange = updatedHoleNumber
                holeChangeRollbackTarget = previousHoleNumber
            }
        }

        Task { await refreshRecommendation() }
    }

    /// Called after the owning view speaks "looks like we're on the next
    /// hole, is that correct?" and gets a voice/manual answer.
    /// - `accepted: true` commits the GPS-suggested hole.
    /// - `accepted: false` with `correctedHoleNumber` commits that hole instead.
    /// - `accepted: false` with no correction rolls back to the hole before
    ///   the pending change, so the same confirmation can be re-asked later.
    func confirmPendingHoleChange(accepted: Bool, correctedHoleNumber: Int? = nil) {
        guard let pending = pendingHoleChange else { return }

        if accepted {
            activeRound?.currentHoleNumber = pending
            holeConfirmedByVoice[pending] = true
        } else if let corrected = correctedHoleNumber {
            holeDetector?.overrideCurrentHole(corrected)
            activeRound?.currentHoleNumber = corrected
            holeConfirmedByVoice[corrected] = false
        } else if let rollback = holeChangeRollbackTarget {
            holeDetector?.overrideCurrentHole(rollback)
        }

        pendingHoleChange = nil
        holeChangeRollbackTarget = nil
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
            onRoundEvent?(.holeRecorded(HoleRecordSnapshot(
                holeNumber: hole.number,
                transitionWasConfirmedByVoice: holeConfirmedByVoice[hole.number] ?? true,
                distanceAskedYards: result.distanceYards,
                recommendedClub: result.recommendedClub,
                windDescription: result.windDescription,
                wasInterpolatedClubPick: result.isInterpolated
            )))
        } catch {
            spokenPhrase = "Couldn't get wind data right now."
        }
    }

    /// Answers a voice question (from either the AirPods or, later, the Siri
    /// path) using the same `CaddyBrain` + `ResponsePhraser` the on-screen
    /// display uses — one source of truth for what Nigel says. `queryType`
    /// isn't used to shorten the phrase yet (v1 always speaks the full
    /// distance-and-club sentence); that's a reasonable simplification since
    /// there's only one phrasing to maintain instead of three.
    func answerQuery(_ query: CaddyQuery) async -> String? {
        guard let round = activeRound, let location = currentLocation else { return nil }
        let holeNumber = query.holeOverride ?? round.currentHoleNumber
        guard let hole = round.courseSnapshot.hole(number: holeNumber) else {
            return "I don't have hole \(holeNumber) for this course."
        }
        do {
            let wind = try await weatherProvider.currentWind(at: hole.green.center)
            let result = caddyBrain.recommendation(
                playerLocation: location,
                green: hole.green,
                target: query.target,
                wind: wind,
                clubs: clubProfile
            )
            return responsePhraser.phrase(hole: hole.number, target: query.target, recommendation: result)
        } catch {
            return "I couldn't get wind data just now."
        }
    }
}
