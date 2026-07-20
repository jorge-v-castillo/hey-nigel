import Testing
@testable import HeyNigelCore

@Suite("ResponsePhraser")
struct ResponsePhraserTests {
    @Test("phrases a windy recommendation in caddy language")
    func windyPhrase() {
        let recommendation = ClubRecommendation(
            distanceYards: 145,
            windAdjustedYards: 155,
            recommendedClub: "8 Iron",
            windDescription: "steady 10 mph headwind",
            adjustmentNote: "move up a club",
            isInterpolated: false
        )
        let sentence = ResponsePhraser().phrase(hole: 7, target: .center, recommendation: recommendation)
        #expect(sentence.contains("hole 7"))
        #expect(sentence.contains("145 yards"))
        #expect(sentence.contains("steady 10 mph headwind"))
        #expect(sentence.contains("move up a club"))
        #expect(sentence.contains("8 Iron"))
    }

    @Test("phrases a calm recommendation without wind language")
    func calmPhrase() {
        let recommendation = ClubRecommendation(
            distanceYards: 150,
            windAdjustedYards: 150,
            recommendedClub: "7 Iron",
            windDescription: "calm conditions",
            adjustmentNote: "play your normal yardage",
            isInterpolated: false
        )
        let sentence = ResponsePhraser().phrase(hole: 12, target: .center, recommendation: recommendation)
        #expect(sentence.contains("Calm out there"))
        #expect(sentence.contains("7 Iron"))
    }

    @Test("hedges the response when the club was interpolated")
    func interpolatedHedge() {
        let recommendation = ClubRecommendation(
            distanceYards: 115,
            windAdjustedYards: 115,
            recommendedClub: "9 Iron",
            windDescription: "calm conditions",
            adjustmentNote: "play your normal yardage",
            isInterpolated: true
        )
        let sentence = ResponsePhraser().phrase(hole: 3, target: .center, recommendation: recommendation)
        #expect(sentence.contains("estimate"))
    }

    @Test("front and back of the green are named explicitly, center is implicit")
    func targetLabels() {
        let recommendation = ClubRecommendation(
            distanceYards: 140, windAdjustedYards: 140, recommendedClub: "8 Iron",
            windDescription: "calm conditions", adjustmentNote: "play your normal yardage", isInterpolated: false
        )
        let frontSentence = ResponsePhraser().phrase(hole: 5, target: .front, recommendation: recommendation)
        let centerSentence = ResponsePhraser().phrase(hole: 5, target: .center, recommendation: recommendation)
        #expect(frontSentence.contains("front of the green"))
        #expect(centerSentence.contains("the green"))
        #expect(!centerSentence.contains("center of the green"))
    }
}
