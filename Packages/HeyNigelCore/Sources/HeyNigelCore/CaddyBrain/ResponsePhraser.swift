import Foundation

/// Turns a `ClubRecommendation` into the sentence Nigel actually speaks.
/// Shared verbatim by the Siri dialog path and the AirPods `AVSpeechSynthesizer`
/// path so there's exactly one voice, not two divergent phrasings.
public struct ResponsePhraser: Sendable {
    public init() {}

    public func phrase(hole: Int, target: GreenTarget, recommendation: ClubRecommendation) -> String {
        let distance = Int(recommendation.distanceYards.rounded())
        let targetLabel = target == .center ? "the green" : "the \(target.rawValue) of the green"

        var sentence = "You're on hole \(hole), about \(distance) yards to \(targetLabel)."

        if recommendation.windDescription == "calm conditions" {
            sentence += " Calm out there — go with your \(recommendation.recommendedClub)."
        } else {
            sentence += " We've got a \(recommendation.windDescription), so I'd \(recommendation.adjustmentNote) — \(recommendation.recommendedClub)."
        }

        if recommendation.isInterpolated {
            sentence += " That's an estimate based on your bag — let me know how it plays."
        }

        return sentence
    }
}
