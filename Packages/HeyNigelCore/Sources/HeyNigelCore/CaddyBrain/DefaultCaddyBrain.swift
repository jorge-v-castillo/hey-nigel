import Foundation

public struct DefaultCaddyBrain: CaddyBrain {
    private let constants: WindAdjustmentConstants
    private let interpolator: ClubBagInterpolator

    public init(
        constants: WindAdjustmentConstants = .standard,
        interpolator: ClubBagInterpolator = ClubBagInterpolator()
    ) {
        self.constants = constants
        self.interpolator = interpolator
    }

    public func recommendation(
        playerLocation: Coordinate,
        green: GreenCoordinates,
        target: GreenTarget,
        wind: WindObservation,
        clubs: PlayerClubProfile
    ) -> ClubRecommendation {
        let targetCoordinate = green.coordinate(for: target)
        let distanceYards = Geodesy.distanceYards(playerLocation, targetCoordinate)
        let bearingToTarget = Geodesy.bearingDegrees(from: playerLocation, to: targetCoordinate)

        // Convert wind's "from" bearing to the bearing it's blowing *toward*.
        let windTravelBearing = (wind.directionFromDegrees + 180).truncatingRemainder(dividingBy: 360)
        let relativeAngle = Geodesy.normalizedAngleDifference(bearingToTarget, windTravelBearing)
        let relativeRadians = relativeAngle.radians

        // relativeAngle == 180 means wind travels opposite the shot (headwind, positive).
        // relativeAngle == 0 means wind travels with the shot (tailwind, negative).
        let headwindComponent = -wind.speedMph * cos(relativeRadians)
        let crosswindComponent = wind.speedMph * sin(relativeRadians)

        let windFactor = headwindComponent >= 0 ? constants.headwindYardsPerMph : constants.tailwindYardsPerMph
        let effectiveYards = distanceYards + headwindComponent * windFactor

        let (club, isInterpolated) = interpolator.recommendClub(forEffectiveYards: effectiveYards, profile: clubs)

        return ClubRecommendation(
            distanceYards: distanceYards,
            windAdjustedYards: effectiveYards,
            recommendedClub: club.name,
            windDescription: Self.describeWind(headwindComponent: headwindComponent, crosswindComponent: crosswindComponent, wind: wind),
            adjustmentNote: Self.describeAdjustment(distanceYards: distanceYards, effectiveYards: effectiveYards),
            isInterpolated: isInterpolated
        )
    }

    private static func describeWind(headwindComponent: Double, crosswindComponent: Double, wind: WindObservation) -> String {
        guard wind.speedMph >= 1 else { return "calm conditions" }
        let speed = Int(wind.speedMph.rounded())
        if abs(headwindComponent) >= abs(crosswindComponent) {
            let kind = headwindComponent >= 0 ? "headwind" : "tailwind"
            return "steady \(speed) mph \(kind)"
        } else {
            return "steady \(speed) mph crosswind"
        }
    }

    private static func describeAdjustment(distanceYards: Double, effectiveYards: Double) -> String {
        let delta = effectiveYards - distanceYards
        if delta > 3 {
            return "move up a club"
        } else if delta < -3 {
            return "take a bit less club"
        } else {
            return "play your normal yardage"
        }
    }
}
