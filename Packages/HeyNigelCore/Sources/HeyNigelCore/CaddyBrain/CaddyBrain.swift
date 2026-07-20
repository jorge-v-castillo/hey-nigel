import Foundation

/// The single source of truth for "what should the player do." Pure and
/// synchronous — no Location/Weather/Speech dependency — so the Siri path,
/// the AirPods path, and any future manual-entry screen all call the exact
/// same tested logic instead of three divergent implementations.
public protocol CaddyBrain {
    func recommendation(
        playerLocation: Coordinate,
        green: GreenCoordinates,
        target: GreenTarget,
        wind: WindObservation,
        clubs: PlayerClubProfile
    ) -> ClubRecommendation
}
